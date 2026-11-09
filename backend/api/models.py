from django.contrib.auth.base_user import BaseUserManager
from django.contrib.auth.models import AbstractUser
from django.db import models
from django.utils import timezone


class UserManager(BaseUserManager):
    use_in_migrations = True

    def _create_user(self, email, password, **extra_fields):
        if not email:
            raise ValueError("An email address is required.")
        user = self.model(email=self.normalize_email(email).lower(), **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_user(self, email, password=None, **extra_fields):
        extra_fields.setdefault("is_staff", False)
        extra_fields.setdefault("is_superuser", False)
        return self._create_user(email, password, **extra_fields)

    def create_superuser(self, email, password=None, **extra_fields):
        extra_fields.setdefault("is_staff", True)
        extra_fields.setdefault("is_superuser", True)
        extra_fields.setdefault("role", User.Role.ADMIN)
        if extra_fields.get("is_staff") is not True:
            raise ValueError("Superuser must have is_staff=True.")
        if extra_fields.get("is_superuser") is not True:
            raise ValueError("Superuser must have is_superuser=True.")
        return self._create_user(email, password, **extra_fields)


class User(AbstractUser):
    class Role(models.TextChoices):
        USER = "user", "User"
        ADMIN = "admin", "Admin"

    username = None
    email = models.EmailField(unique=True)
    name = models.CharField(max_length=120)
    role = models.CharField(max_length=10, choices=Role.choices, default=Role.USER)
    preferences = models.JSONField(default=dict, blank=True)
    is_email_verified = models.BooleanField(default=False)
    date_joined = models.DateTimeField(default=timezone.now)

    USERNAME_FIELD = "email"
    REQUIRED_FIELDS = ["name"]
    objects = UserManager()

    def save(self, *args, **kwargs):
        self.email = self.email.strip().lower()
        if self.is_staff or self.is_superuser:
            self.role = self.Role.ADMIN
        super().save(*args, **kwargs)

    def __str__(self):
        return self.email


class FoodCategory(models.Model):
    name = models.CharField(max_length=80, unique=True)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["name"]

    def __str__(self):
        return self.name


class Food(models.Model):
    class Status(models.TextChoices):
        DRAFT = "draft", "Draft"
        PUBLISHED = "published", "Published"
        ARCHIVED = "archived", "Archived"

    name = models.CharField(max_length=160)
    barcode = models.CharField(max_length=32, blank=True, db_index=True)
    description = models.TextField(blank=True)
    category = models.ForeignKey(
        FoodCategory, on_delete=models.PROTECT, related_name="foods"
    )
    serving_size = models.DecimalField(max_digits=8, decimal_places=2, default=100)
    serving_unit = models.CharField(max_length=32, default="g")
    calories = models.PositiveIntegerField(default=0)
    protein = models.DecimalField(max_digits=8, decimal_places=2, default=0)
    carbs = models.DecimalField(max_digits=8, decimal_places=2, default=0)
    fat = models.DecimalField(max_digits=8, decimal_places=2, default=0)
    data_source = models.CharField(max_length=200, blank=True)
    status = models.CharField(
        max_length=12, choices=Status.choices, default=Status.DRAFT
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["name"]

    def __str__(self):
        return self.name


class MealRecord(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="meals")
    food = models.ForeignKey(
        Food,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="meal_records",
    )
    servings = models.DecimalField(max_digits=6, decimal_places=2, default=1)
    name = models.CharField(max_length=160)
    category = models.CharField(max_length=40)
    calories = models.PositiveIntegerField()
    protein = models.PositiveIntegerField()
    carbs = models.PositiveIntegerField()
    fat = models.PositiveIntegerField()
    notes = models.CharField(max_length=500, blank=True)
    created_at = models.DateTimeField(default=timezone.now)

    class Meta:
        ordering = ["-created_at"]


class DailyWater(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="water")
    date = models.DateField()
    amount_ml = models.PositiveIntegerField(default=0)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        constraints = [
            models.UniqueConstraint(fields=["user", "date"], name="unique_user_water_day")
        ]
        ordering = ["-date"]


class WaterLogEntry(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="water_entries")
    amount_ml = models.PositiveIntegerField()
    recorded_at = models.DateTimeField(default=timezone.now)

    class Meta:
        ordering = ["-recorded_at"]


class BodyMeasurement(models.Model):
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name="body_measurements",
    )
    weight_kg = models.DecimalField(max_digits=5, decimal_places=2)
    height_cm = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        null=True,
        blank=True,
    )
    measured_at = models.DateTimeField(default=timezone.now)

    class Meta:
        ordering = ["-measured_at"]


class EmailActionCode(models.Model):
    class Purpose(models.TextChoices):
        VERIFY_EMAIL = "verify_email", "Verify email"
        RESET_PASSWORD = "reset_password", "Reset password"

    user = models.ForeignKey(User, on_delete=models.CASCADE)
    purpose = models.CharField(max_length=20, choices=Purpose.choices)
    code_hash = models.CharField(max_length=64)
    expires_at = models.DateTimeField()
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]


class EducationArticle(models.Model):
    title = models.CharField(max_length=160)
    summary = models.CharField(max_length=320)
    category = models.CharField(max_length=80)
    body = models.TextField()
    is_published = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-updated_at"]


class RecommendationRule(models.Model):
    title = models.CharField(max_length=160)
    description = models.TextField()
    message = models.CharField(max_length=500)
    trigger = models.CharField(max_length=40, default="manual")
    is_active = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["title"]


class Announcement(models.Model):
    title = models.CharField(max_length=160)
    body = models.TextField()
    publish_at = models.DateTimeField(default=timezone.now)
    is_active = models.BooleanField(default=True)
    created_by = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        related_name="announcements",
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-publish_at"]


class AuditEvent(models.Model):
    actor = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        related_name="audit_events",
    )
    action = models.CharField(max_length=80)
    target = models.CharField(max_length=160, blank=True)
    details = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]
