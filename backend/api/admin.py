from django.contrib import admin
from django.contrib.auth.forms import UserChangeForm, UserCreationForm
from django.contrib.auth.admin import UserAdmin as DjangoUserAdmin

from .models import DailyWater, Food, FoodCategory, MealRecord, User


class NutriMateUserCreationForm(UserCreationForm):
    class Meta:
        model = User
        fields = ("email", "name")


class NutriMateUserChangeForm(UserChangeForm):
    class Meta:
        model = User
        fields = "__all__"


@admin.register(User)
class UserAdmin(DjangoUserAdmin):
    form = NutriMateUserChangeForm
    add_form = NutriMateUserCreationForm
    ordering = ("email",)
    list_display = ("email", "name", "role", "is_active", "is_staff")
    search_fields = ("email", "name")
    fieldsets = (
        (None, {"fields": ("email", "password")}),
        ("Personal info", {"fields": ("name",)}),
        ("Permissions", {"fields": ("role", "is_active", "is_staff", "is_superuser", "groups", "user_permissions")}),
        ("Dates", {"fields": ("last_login", "date_joined")}),
    )
    add_fieldsets = (
        (None, {"classes": ("wide",), "fields": ("email", "name", "password1", "password2")}),
    )
    filter_horizontal = ("groups", "user_permissions")


admin.site.register(FoodCategory)
admin.site.register(Food)
admin.site.register(MealRecord)
admin.site.register(DailyWater)
