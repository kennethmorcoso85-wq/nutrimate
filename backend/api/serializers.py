from decimal import Decimal, ROUND_HALF_UP

from django.contrib.auth.password_validation import validate_password
from rest_framework import serializers

from .models import DailyWater, Food, FoodCategory, MealRecord, User


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ["id", "name", "email", "role", "is_active", "date_joined"]
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
