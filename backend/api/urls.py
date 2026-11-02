from django.urls import include, path
from rest_framework.routers import DefaultRouter
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView

from .views import (
    AdminDashboardView,
    AdminCreateUserView,
    AdminUserViewSet,
    CurrentUserView,
    FoodCategoryViewSet,
    FoodViewSet,
    HealthView,
    MealRecordViewSet,
    RegisterView,
    TodayWaterView,
)


router = DefaultRouter()
router.register("admin/users", AdminUserViewSet, basename="admin-users")
router.register("categories", FoodCategoryViewSet, basename="categories")
router.register("foods", FoodViewSet, basename="foods")
router.register("meals", MealRecordViewSet, basename="meals")

urlpatterns = [
    path("health/", HealthView.as_view(), name="health"),
    path("auth/register/", RegisterView.as_view(), name="register"),
    path("auth/token/", TokenObtainPairView.as_view(), name="token-obtain-pair"),
    path("auth/token/refresh/", TokenRefreshView.as_view(), name="token-refresh"),
    path("auth/me/", CurrentUserView.as_view(), name="current-user"),
    path("admin/dashboard/", AdminDashboardView.as_view(), name="admin-dashboard"),
    path("admin/users/create/", AdminCreateUserView.as_view(), name="admin-create-user"),
    path("water/today/", TodayWaterView.as_view(), name="today-water"),
    path("", include(router.urls)),
]
