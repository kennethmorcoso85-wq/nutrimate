from django.db.models import Q
from django.db.models.deletion import ProtectedError
from django.utils import timezone
from rest_framework import generics, mixins, permissions, status, viewsets
from rest_framework.exceptions import PermissionDenied
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import DailyWater, Food, FoodCategory, MealRecord, User
from .permissions import IsAdminRole
from .serializers import (
    DailyWaterSerializer,
    FoodCategorySerializer,
    FoodSerializer,
    MealRecordSerializer,
    RegistrationSerializer,
    UserSerializer,
)


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


class CurrentUserView(APIView):
    def get(self, request):
        return Response(UserSerializer(request.user).data)


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
            }
        )


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
        return Response(self.get_serializer(target).data)


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
            return Response(
                {"detail": "Category is in use; it has been archived instead."},
                status=status.HTTP_200_OK,
            )
        return super().destroy(request, *args, **kwargs)


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
        return queryset


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
