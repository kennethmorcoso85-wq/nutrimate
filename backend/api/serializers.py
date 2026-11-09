from decimal import Decimal, ROUND_HALF_UP

from django.contrib.auth.password_validation import validate_password
from rest_framework import serializers

from .models import (
    Announcement,
    AuditEvent,
    BodyMeasurement,
    DailyWater,
    EducationArticle,
    Food,
    FoodCategory,
    MealRecord,
    RecommendationRule,
    User,
    WaterLogEntry,
)


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = [
            "id",
            "name",
            "email",
            "role",
            "is_active",
            "is_email_verified",
            "preferences",
            "date_joined",
        ]
        read_only_fields = [
            "id",
            "email",
            "role",
            "is_active",
            "is_email_verified",
            "date_joined",
        ]

    def validate_preferences(self, value):
        if not isinstance(value, dict):
            raise serializers.ValidationError("Preferences must be an object.")
        if len(value) > 30:
            raise serializers.ValidationError("Too many preference fields.")
        return value


class ChangePasswordSerializer(serializers.Serializer):
    current_password = serializers.CharField(write_only=True)
    new_password = serializers.CharField(write_only=True)

    def validate_new_password(self, value):
        validate_password(value, user=self.context["request"].user)
        return value


class EmailCodeSerializer(serializers.Serializer):
    code = serializers.RegexField(r"^\d{6}$")


class PasswordResetSerializer(serializers.Serializer):
    email = serializers.EmailField()
    code = serializers.RegexField(r"^\d{6}$")
    new_password = serializers.CharField(write_only=True)

    def validate_new_password(self, value):
        validate_password(value)
        return value


class EducationArticleSerializer(serializers.ModelSerializer):
    class Meta:
        model = EducationArticle
        fields = [
            "id",
            "title",
            "summary",
            "category",
            "body",
            "is_published",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["id", "created_at", "updated_at"]


class RecommendationRuleSerializer(serializers.ModelSerializer):
    class Meta:
        model = RecommendationRule
        fields = [
            "id",
            "title",
            "description",
            "message",
            "trigger",
            "is_active",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["id", "created_at", "updated_at"]


class AnnouncementSerializer(serializers.ModelSerializer):
    class Meta:
        model = Announcement
        fields = [
            "id",
            "title",
            "body",
            "publish_at",
            "is_active",
            "created_at",
        ]
        read_only_fields = ["id", "created_at"]


class AuditEventSerializer(serializers.ModelSerializer):
    actor_name = serializers.CharField(source="actor.name", read_only=True)

    class Meta:
        model = AuditEvent
        fields = ["id", "actor_name", "action", "target", "details", "created_at"]
        read_only_fields = fields


class RegistrationSerializer(serializers.ModelSerializer):
    password = serializers.CharField(
        write_only=True, validators=[validate_password], min_length=8
    )

    class Meta:
        model = User
        fields = ["name", "email", "password"]

    def create(self, validated_data):
        return User.objects.create_user(
            name=validated_data["name"].strip(),
            email=validated_data["email"],
            password=validated_data["password"],
            role=User.Role.USER,
        )


class FoodCategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = FoodCategory
        fields = ["id", "name", "is_active", "created_at"]
        read_only_fields = ["id", "created_at"]


class FoodSerializer(serializers.ModelSerializer):
    category_name = serializers.CharField(source="category.name", read_only=True)

    class Meta:
        model = Food
        fields = [
            "id",
            "name",
            "barcode",
            "description",
            "category",
            "category_name",
            "serving_size",
            "serving_unit",
            "calories",
            "protein",
            "carbs",
            "fat",
            "data_source",
            "status",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["id", "category_name", "created_at", "updated_at"]


class MealRecordSerializer(serializers.ModelSerializer):
    food = serializers.PrimaryKeyRelatedField(
        queryset=Food.objects.filter(
            status=Food.Status.PUBLISHED,
            category__is_active=True,
        ),
        required=False,
    )
    servings = serializers.DecimalField(
        max_digits=6,
        decimal_places=2,
        min_value=Decimal("0.01"),
        max_value=Decimal("100.00"),
        required=False,
    )

    class Meta:
        model = MealRecord
        fields = [
            "id",
            "food",
            "servings",
            "name",
            "category",
            "calories",
            "protein",
            "carbs",
            "fat",
            "notes",
            "created_at",
        ]
        read_only_fields = ["id"]
        extra_kwargs = {"created_at": {"required": False}}

    def validate(self, attrs):
        food = attrs.get("food", self.instance.food if self.instance else None)
        if food is None:
            return attrs

        servings = attrs.get(
            "servings",
            self.instance.servings if self.instance else Decimal("1"),
        )
        attrs["servings"] = servings
        attrs["name"] = food.name
        attrs["calories"] = int(
            (Decimal(food.calories) * servings).quantize(
                Decimal("1"),
                rounding=ROUND_HALF_UP,
            )
        )
        for nutrient in ("protein", "carbs", "fat"):
            attrs[nutrient] = int(
                (getattr(food, nutrient) * servings).quantize(
                    Decimal("1"),
                    rounding=ROUND_HALF_UP,
                )
            )
        return attrs


class DailyWaterSerializer(serializers.ModelSerializer):
    class Meta:
        model = DailyWater
        fields = ["date", "amount_ml", "updated_at"]
        read_only_fields = ["date", "updated_at"]

    def validate_amount_ml(self, value):
        if value > 15000:
            raise serializers.ValidationError("Daily water amount cannot exceed 15000 ml.")
        return value


class WaterLogEntrySerializer(serializers.ModelSerializer):
    class Meta:
        model = WaterLogEntry
        fields = ["id", "amount_ml", "recorded_at"]
        read_only_fields = ["id"]
        extra_kwargs = {"recorded_at": {"required": False}}

    def validate_amount_ml(self, value):
        if value <= 0 or value > 5000:
            raise serializers.ValidationError(
                "A water entry must be between 1 and 5000 ml."
            )
        return value


class BodyMeasurementSerializer(serializers.ModelSerializer):
    class Meta:
        model = BodyMeasurement
        fields = ["id", "weight_kg", "height_cm", "measured_at"]
        read_only_fields = ["id"]
        extra_kwargs = {"measured_at": {"required": False}}

    def validate_weight_kg(self, value):
        if value <= 0 or value > 500:
            raise serializers.ValidationError(
                "Weight must be greater than 0 and no more than 500 kg."
            )
        return value

    def validate_height_cm(self, value):
        if value is not None and (value < 50 or value > 300):
            raise serializers.ValidationError(
                "Height must be between 50 and 300 cm."
            )
        return value
