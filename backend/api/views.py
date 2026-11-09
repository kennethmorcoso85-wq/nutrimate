import hashlib
import secrets
from datetime import date, timedelta
from smtplib import SMTPException

from django.conf import settings
from django.contrib.auth.password_validation import validate_password
from django.core.mail import send_mail
from django.db import transaction
from django.db.models import Q
from django.db.models.deletion import ProtectedError
from django.utils import timezone
from rest_framework import generics, mixins, permissions, status, viewsets
from rest_framework.exceptions import APIException, PermissionDenied, ValidationError
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import (
    Announcement,
    AuditEvent,
    BodyMeasurement,
    DailyWater,
    EducationArticle,
    EmailActionCode,
    Food,
    FoodCategory,
    MealRecord,
    RecommendationRule,
    User,
    WaterLogEntry,
)
from .permissions import IsAdminRole
from .serializers import (
    AnnouncementSerializer,
    AuditEventSerializer,
    BodyMeasurementSerializer,
    ChangePasswordSerializer,
    DailyWaterSerializer,
    EducationArticleSerializer,
    EmailCodeSerializer,
    FoodCategorySerializer,
    FoodSerializer,
    MealRecordSerializer,
    PasswordResetSerializer,
    RecommendationRuleSerializer,
    RegistrationSerializer,
    UserSerializer,
    WaterLogEntrySerializer,
)


class EmailDeliveryError(APIException):
    status_code = status.HTTP_503_SERVICE_UNAVAILABLE
    default_detail = "Email delivery is unavailable. Check the backend email configuration."
    default_code = "email_unavailable"


def record_audit(actor, action, target="", details=None):
    AuditEvent.objects.create(
        actor=actor,
        action=action,
        target=str(target),
        details=details or {},
    )


def _create_email_code(user, purpose):
    code = f"{secrets.randbelow(1_000_000):06d}"
    EmailActionCode.objects.filter(user=user, purpose=purpose).delete()
    EmailActionCode.objects.create(
        user=user,
        purpose=purpose,
        code_hash=hashlib.sha256(code.encode()).hexdigest(),
        expires_at=timezone.now() + timedelta(minutes=15),
    )
    return code


def _send_email_code(user, purpose, code):
    if purpose == EmailActionCode.Purpose.VERIFY_EMAIL:
        subject = "Verify your NutriMate email"
        message = f"Your NutriMate verification code is {code}. It expires in 15 minutes."
    else:
        subject = "Reset your NutriMate password"
        message = f"Your NutriMate password reset code is {code}. It expires in 15 minutes."
    try:
        send_mail(subject, message, settings.DEFAULT_FROM_EMAIL, [user.email])
    except (OSError, SMTPException) as error:
        EmailActionCode.objects.filter(user=user, purpose=purpose).delete()
        raise EmailDeliveryError() from error


def _consume_email_code(user, purpose, code):
    code_hash = hashlib.sha256(code.encode()).hexdigest()
    challenge = EmailActionCode.objects.filter(
        user=user,
        purpose=purpose,
        code_hash=code_hash,
        expires_at__gt=timezone.now(),
    ).first()
    if challenge is None:
        raise ValidationError({"code": "The code is invalid or has expired."})
    challenge.delete()


class HealthView(APIView):
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        return Response({"status": "ok", "service": "NutriMate API"})


class RegisterView(generics.CreateAPIView):
    serializer_class = RegistrationSerializer
    permission_classes = [permissions.AllowAny]


class AdminCreateUserView(generics.CreateAPIView):
    serializer_class = RegistrationSerializer
    permission_classes = [IsAdminRole]

    def perform_create(self, serializer):
        user = serializer.save()
        record_audit(self.request.user, "user.created", user.email)


class CurrentUserView(APIView):
    def get(self, request):
        return Response(UserSerializer(request.user).data)

    def patch(self, request):
        serializer = UserSerializer(
            request.user,
            data=request.data,
            partial=True,
        )
        serializer.is_valid(raise_exception=True)
        serializer.save()
        record_audit(request.user, "profile.updated", request.user.email)
        return Response(serializer.data)


class AccountExportView(APIView):
    def get(self, request):
        return Response(
            {
                "account": UserSerializer(request.user).data,
                "meals": MealRecordSerializer(
                    MealRecord.objects.filter(user=request.user),
                    many=True,
                ).data,
                "water_entries": WaterLogEntrySerializer(
                    WaterLogEntry.objects.filter(user=request.user),
                    many=True,
                ).data,
                "water": DailyWaterSerializer(
                    DailyWater.objects.filter(user=request.user),
                    many=True,
                ).data,
                "measurements": BodyMeasurementSerializer(
                    BodyMeasurement.objects.filter(user=request.user),
                    many=True,
                ).data,
            }
        )


class ChangePasswordView(APIView):
    def post(self, request):
        serializer = ChangePasswordSerializer(
            data=request.data,
            context={"request": request},
        )
        serializer.is_valid(raise_exception=True)
        if not request.user.check_password(serializer.validated_data["current_password"]):
            raise ValidationError({"current_password": "The current password is incorrect."})
        request.user.set_password(serializer.validated_data["new_password"])
        request.user.save(update_fields=["password"])
        record_audit(request.user, "account.password_changed", request.user.email)
        return Response(status=status.HTTP_204_NO_CONTENT)


class DeleteAccountView(APIView):
    def delete(self, request):
        password = request.data.get("password")
        if not isinstance(password, str) or not request.user.check_password(password):
            raise ValidationError({"password": "Enter your current password to delete the account."})
        if request.user.is_staff and not User.objects.filter(
            is_staff=True,
            is_active=True,
        ).exclude(pk=request.user.pk).exists():
            raise ValidationError(
                {"detail": "The last active admin account cannot be deleted."}
            )
        email = request.user.email
        record_audit(request.user, "account.deleted", email)
        request.user.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)


class RequestEmailVerificationView(APIView):
    def post(self, request):
        user = request.user
        if user.is_email_verified:
            return Response({"detail": "This email address is already verified."})
        code = _create_email_code(user, EmailActionCode.Purpose.VERIFY_EMAIL)
        _send_email_code(user, EmailActionCode.Purpose.VERIFY_EMAIL, code)
        delivery = (
            "The code was printed to the backend console."
            if settings.EMAIL_BACKEND.endswith("console.EmailBackend")
            else "A verification code has been sent to your email."
        )
        return Response({"detail": delivery})


class ConfirmEmailVerificationView(APIView):
    def post(self, request):
        serializer = EmailCodeSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        _consume_email_code(
            request.user,
            EmailActionCode.Purpose.VERIFY_EMAIL,
            serializer.validated_data["code"],
        )
        request.user.is_email_verified = True
        request.user.save(update_fields=["is_email_verified"])
        record_audit(request.user, "account.email_verified", request.user.email)
        return Response(UserSerializer(request.user).data)


class RequestPasswordResetView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        email = request.data.get("email", "")
        if not isinstance(email, str):
            raise ValidationError({"email": "Enter a valid email address."})
        user = User.objects.filter(email__iexact=email.strip(), is_active=True).first()
        if user is not None:
            code = _create_email_code(user, EmailActionCode.Purpose.RESET_PASSWORD)
            _send_email_code(user, EmailActionCode.Purpose.RESET_PASSWORD, code)
        return Response(
            {"detail": "If the account exists, a password reset code has been sent."}
        )


class ConfirmPasswordResetView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = PasswordResetSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = User.objects.filter(
            email__iexact=serializer.validated_data["email"].strip(),
            is_active=True,
        ).first()
        if user is None:
            raise ValidationError({"code": "The code is invalid or has expired."})
        _consume_email_code(
            user,
            EmailActionCode.Purpose.RESET_PASSWORD,
            serializer.validated_data["code"],
        )
        user.set_password(serializer.validated_data["new_password"])
        user.save(update_fields=["password"])
        record_audit(user, "account.password_reset", user.email)
        return Response(status=status.HTTP_204_NO_CONTENT)


class AdminDashboardView(APIView):
    permission_classes = [IsAdminRole]

    def get(self, request):
        today = timezone.localdate()
        return Response(
            {
                "registered_accounts": User.objects.count(),
                "active_accounts": User.objects.filter(is_active=True).count(),
                "meal_records": MealRecord.objects.count(),
                "food_categories": FoodCategory.objects.filter(is_active=True).count(),
                "food_records": Food.objects.count(),
                "published_food_records": Food.objects.filter(
                    status=Food.Status.PUBLISHED
                ).count(),
                "incomplete_food_records": Food.objects.filter(
                    Q(name="")
                    | Q(serving_size__lte=0)
                    | Q(serving_unit="")
                ).exclude(status=Food.Status.ARCHIVED).count(),
                "new_registrations_today": User.objects.filter(
                    date_joined__date=today
                ).count(),
                "published_articles": EducationArticle.objects.filter(
                    is_published=True
                ).count(),
                "active_recommendations": RecommendationRule.objects.filter(
                    is_active=True
                ).count(),
                "active_announcements": Announcement.objects.filter(
                    is_active=True, publish_at__lte=timezone.now()
                ).count(),
                "audit_events": AuditEvent.objects.count(),
            }
        )


class AdminReportView(APIView):
    permission_classes = [IsAdminRole]

    def get(self, request):
        end = timezone.localdate()
        start = end - timedelta(days=29)
        try:
            if request.query_params.get("start"):
                start = date.fromisoformat(request.query_params["start"])
            if request.query_params.get("end"):
                end = date.fromisoformat(request.query_params["end"])
        except ValueError as error:
            raise ValidationError(
                {"date": "Dates must use YYYY-MM-DD format."}
            ) from error
        if start > end:
            raise ValidationError({"date": "The start date must not be after the end date."})
        meal_records = MealRecord.objects.filter(
            created_at__date__gte=start,
            created_at__date__lte=end,
        )
        return Response(
            {
                "start": start,
                "end": end,
                "registered_accounts": User.objects.filter(
                    date_joined__date__gte=start,
                    date_joined__date__lte=end,
                ).count(),
                "meal_records": meal_records.count(),
                "meal_days": meal_records.values("created_at__date").distinct().count(),
                "published_food_records": Food.objects.filter(
                    status=Food.Status.PUBLISHED
                ).count(),
                "active_accounts": User.objects.filter(is_active=True).count(),
            }
        )


class EducationArticleViewSet(viewsets.ModelViewSet):
    queryset = EducationArticle.objects.all()
    serializer_class = EducationArticleSerializer

    def get_permissions(self):
        if self.action in {"create", "update", "partial_update", "destroy"}:
            return [IsAdminRole()]
        return [permissions.IsAuthenticated()]

    def get_queryset(self):
        queryset = super().get_queryset()
        if not self.request.user.is_staff:
            queryset = queryset.filter(is_published=True)
        return queryset

    def perform_create(self, serializer):
        article = serializer.save()
        record_audit(self.request.user, "content.created", article.title)

    def perform_update(self, serializer):
        article = serializer.save()
        record_audit(self.request.user, "content.updated", article.title)

    def perform_destroy(self, instance):
        title = instance.title
        instance.delete()
        record_audit(self.request.user, "content.deleted", title)


class RecommendationRuleViewSet(viewsets.ModelViewSet):
    queryset = RecommendationRule.objects.all()
    serializer_class = RecommendationRuleSerializer

    def get_permissions(self):
        if self.action in {"create", "update", "partial_update", "destroy"}:
            return [IsAdminRole()]
        return [permissions.IsAuthenticated()]

    def get_queryset(self):
        queryset = super().get_queryset()
        if not self.request.user.is_staff:
            queryset = queryset.filter(is_active=True)
        return queryset

    def perform_create(self, serializer):
        rule = serializer.save()
        record_audit(self.request.user, "recommendation.created", rule.title)

    def perform_update(self, serializer):
        rule = serializer.save()
        record_audit(self.request.user, "recommendation.updated", rule.title)

    def perform_destroy(self, instance):
        title = instance.title
        instance.delete()
        record_audit(self.request.user, "recommendation.deleted", title)


class AnnouncementViewSet(viewsets.ModelViewSet):
    queryset = Announcement.objects.select_related("created_by").all()
    serializer_class = AnnouncementSerializer

    def get_permissions(self):
        if self.action in {"create", "update", "partial_update", "destroy"}:
            return [IsAdminRole()]
        return [permissions.IsAuthenticated()]

    def get_queryset(self):
        queryset = super().get_queryset()
        if not self.request.user.is_staff:
            queryset = queryset.filter(
                is_active=True,
                publish_at__lte=timezone.now(),
            )
        return queryset

    def perform_create(self, serializer):
        announcement = serializer.save(created_by=self.request.user)
        record_audit(self.request.user, "announcement.created", announcement.title)

    def perform_update(self, serializer):
        announcement = serializer.save()
        record_audit(self.request.user, "announcement.updated", announcement.title)

    def perform_destroy(self, instance):
        title = instance.title
        instance.delete()
        record_audit(self.request.user, "announcement.deleted", title)


class AdminAuditEventViewSet(mixins.ListModelMixin, viewsets.GenericViewSet):
    queryset = AuditEvent.objects.select_related("actor").all()
    serializer_class = AuditEventSerializer
    permission_classes = [IsAdminRole]


class AdminUserViewSet(
    mixins.ListModelMixin,
    mixins.RetrieveModelMixin,
    mixins.UpdateModelMixin,
    viewsets.GenericViewSet,
):
    serializer_class = UserSerializer
    permission_classes = [IsAdminRole]
    queryset = User.objects.all().order_by("-date_joined")
    lookup_field = "pk"

    def get_queryset(self):
        queryset = super().get_queryset()
        search = self.request.query_params.get("search", "").strip()
        if search:
            queryset = queryset.filter(Q(name__icontains=search) | Q(email__icontains=search))
        active = self.request.query_params.get("active")
        if active in {"true", "false"}:
            queryset = queryset.filter(is_active=(active == "true"))
        return queryset

    def partial_update(self, request, *args, **kwargs):
        target = self.get_object()
        if target.pk == request.user.pk:
            raise PermissionDenied("You cannot deactivate your own admin account.")
        value = request.data.get("is_active")
        if not isinstance(value, bool):
            return Response(
                {"is_active": ["Expected a boolean value."]},
                status=status.HTTP_400_BAD_REQUEST,
            )
        target.is_active = value
        target.save(update_fields=["is_active"])
        record_audit(
            request.user,
            "user.activated" if value else "user.deactivated",
            target.email,
        )
        return Response(self.get_serializer(target).data)

    def create(self, request, *args, **kwargs):
        response = super().create(request, *args, **kwargs)
        record_audit(request.user, "user.created", response.data["email"])
        return response


class FoodCategoryViewSet(viewsets.ModelViewSet):
    queryset = FoodCategory.objects.all()
    serializer_class = FoodCategorySerializer

    def get_permissions(self):
        if self.action in {"create", "update", "partial_update", "destroy"}:
            return [IsAdminRole()]
        return [permissions.IsAuthenticated()]

    def get_queryset(self):
        queryset = super().get_queryset()
        if not self.request.user.is_staff:
            queryset = queryset.filter(is_active=True)
        return queryset

    def destroy(self, request, *args, **kwargs):
        category = self.get_object()
        if category.foods.exists():
            category.is_active = False
            category.save(update_fields=["is_active"])
            record_audit(request.user, "category.archived", category.name)
            return Response(
                {"detail": "Category is in use; it has been archived instead."},
                status=status.HTTP_200_OK,
            )
        name = category.name
        response = super().destroy(request, *args, **kwargs)
        record_audit(request.user, "category.deleted", name)
        return response

    def perform_create(self, serializer):
        category = serializer.save()
        record_audit(self.request.user, "category.created", category.name)

    def perform_update(self, serializer):
        category = serializer.save()
        record_audit(self.request.user, "category.updated", category.name)


class FoodViewSet(viewsets.ModelViewSet):
    queryset = Food.objects.select_related("category").all()
    serializer_class = FoodSerializer

    def get_permissions(self):
        if self.action in {"create", "update", "partial_update", "destroy"}:
            return [IsAdminRole()]
        return [permissions.IsAuthenticated()]

    def get_queryset(self):
        queryset = super().get_queryset()
        if not self.request.user.is_staff:
            queryset = queryset.filter(
                status=Food.Status.PUBLISHED, category__is_active=True
            )
        search = self.request.query_params.get("search", "").strip()
        if search:
            queryset = queryset.filter(name__icontains=search)
        category_id = self.request.query_params.get("category")
        if category_id:
            queryset = queryset.filter(category_id=category_id)
        barcode = self.request.query_params.get("barcode", "").strip()
        if barcode:
            queryset = queryset.filter(barcode=barcode)
        return queryset

    def perform_create(self, serializer):
        food = serializer.save()
        record_audit(self.request.user, "food.created", food.name)

    def perform_update(self, serializer):
        food = serializer.save()
        record_audit(self.request.user, "food.updated", food.name)

    def perform_destroy(self, instance):
        name = instance.name
        instance.delete()
        record_audit(self.request.user, "food.deleted", name)


class MealRecordViewSet(viewsets.ModelViewSet):
    serializer_class = MealRecordSerializer

    def get_queryset(self):
        return MealRecord.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


class TodayWaterView(APIView):
    def get(self, request):
        water, _ = DailyWater.objects.get_or_create(
            user=request.user, date=timezone.localdate()
        )
        return Response(DailyWaterSerializer(water).data)

    def put(self, request):
        water, _ = DailyWater.objects.get_or_create(
            user=request.user, date=timezone.localdate()
        )
        serializer = DailyWaterSerializer(water, data=request.data)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(serializer.data)


class WaterLogEntryViewSet(viewsets.ModelViewSet):
    serializer_class = WaterLogEntrySerializer

    def get_queryset(self):
        return WaterLogEntry.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        amount = serializer.validated_data["amount_ml"]
        recorded_at = serializer.validated_data.get("recorded_at", timezone.now())
        day = timezone.localdate(recorded_at)
        with transaction.atomic():
            water, _ = DailyWater.objects.select_for_update().get_or_create(
                user=self.request.user,
                date=day,
            )
            if water.amount_ml + amount > 15000:
                raise ValidationError(
                    {"amount_ml": "Daily water amount cannot exceed 15000 ml."}
                )
            serializer.save(user=self.request.user)
            water.amount_ml += amount
            water.save(update_fields=["amount_ml", "updated_at"])

    def perform_update(self, serializer):
        entry = serializer.instance
        old_amount = entry.amount_ml
        new_amount = serializer.validated_data.get("amount_ml", old_amount)
        old_day = timezone.localdate(entry.recorded_at)
        new_recorded_at = serializer.validated_data.get("recorded_at", entry.recorded_at)
        new_day = timezone.localdate(new_recorded_at)
        with transaction.atomic():
            old_water, _ = DailyWater.objects.select_for_update().get_or_create(
                user=self.request.user,
                date=old_day,
            )
            if old_day == new_day:
                total = old_water.amount_ml - old_amount + new_amount
                if total > 15000:
                    raise ValidationError(
                        {"amount_ml": "Daily water amount cannot exceed 15000 ml."}
                    )
                old_water.amount_ml = total
                old_water.save(update_fields=["amount_ml", "updated_at"])
            else:
                new_water, _ = DailyWater.objects.select_for_update().get_or_create(
                    user=self.request.user,
                    date=new_day,
                )
                if new_water.amount_ml + new_amount > 15000:
                    raise ValidationError(
                        {"amount_ml": "Daily water amount cannot exceed 15000 ml."}
                    )
                old_water.amount_ml = max(0, old_water.amount_ml - old_amount)
                old_water.save(update_fields=["amount_ml", "updated_at"])
                new_water.amount_ml += new_amount
                new_water.save(update_fields=["amount_ml", "updated_at"])
            serializer.save()

    def perform_destroy(self, instance):
        day = timezone.localdate(instance.recorded_at)
        with transaction.atomic():
            water, _ = DailyWater.objects.select_for_update().get_or_create(
                user=self.request.user,
                date=day,
            )
            water.amount_ml = max(0, water.amount_ml - instance.amount_ml)
            water.save(update_fields=["amount_ml", "updated_at"])
            instance.delete()


class BodyMeasurementViewSet(viewsets.ModelViewSet):
    serializer_class = BodyMeasurementSerializer

    def get_queryset(self):
        return BodyMeasurement.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)
