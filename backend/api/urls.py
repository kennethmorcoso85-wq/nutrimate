from django.urls import include, path
from rest_framework.routers import DefaultRouter
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView

from .views import (
    AdminDashboardView,
    AdminCreateUserView,
    AdminAuditEventViewSet,
    AdminUserViewSet,
    AdminReportView,
    AccountExportView,
    BodyMeasurementViewSet,
    AnnouncementViewSet,
    ChangePasswordView,
    ConfirmEmailVerificationView,
    ConfirmPasswordResetView,
    CurrentUserView,
    DeleteAccountView,
    EducationArticleViewSet,
    FoodCategoryViewSet,
    FoodViewSet,
    HealthView,
    MealRecordViewSet,
    RecommendationRuleViewSet,
    RegisterView,
    RequestEmailVerificationView,
    RequestPasswordResetView,
    TodayWaterView,
    WaterLogEntryViewSet,
)


router = DefaultRouter()
router.register("admin/users", AdminUserViewSet, basename="admin-users")
router.register("admin/audit", AdminAuditEventViewSet, basename="admin-audit")
router.register("categories", FoodCategoryViewSet, basename="categories")
router.register("foods", FoodViewSet, basename="foods")
router.register("meals", MealRecordViewSet, basename="meals")
router.register("water/entries", WaterLogEntryViewSet, basename="water-entries")
router.register("measurements", BodyMeasurementViewSet, basename="measurements")
router.register("content", EducationArticleViewSet, basename="content")
router.register(
    "recommendations",
    RecommendationRuleViewSet,
    basename="recommendations",
)
router.register("announcements", AnnouncementViewSet, basename="announcements")

urlpatterns = [
    path("health/", HealthView.as_view(), name="health"),
    path("auth/register/", RegisterView.as_view(), name="register"),
    path("auth/token/", TokenObtainPairView.as_view(), name="token-obtain-pair"),
    path("auth/token/refresh/", TokenRefreshView.as_view(), name="token-refresh"),
    path("auth/me/", CurrentUserView.as_view(), name="current-user"),
    path("auth/export/", AccountExportView.as_view(), name="account-export"),
    path("auth/change-password/", ChangePasswordView.as_view(), name="change-password"),
    path(
        "auth/email/verification/request/",
        RequestEmailVerificationView.as_view(),
        name="request-email-verification",
    ),
    path(
        "auth/email/verification/confirm/",
        ConfirmEmailVerificationView.as_view(),
        name="confirm-email-verification",
    ),
    path(
        "auth/password/reset/request/",
        RequestPasswordResetView.as_view(),
        name="request-password-reset",
    ),
    path(
        "auth/password/reset/confirm/",
        ConfirmPasswordResetView.as_view(),
        name="confirm-password-reset",
    ),
    path("auth/account/", DeleteAccountView.as_view(), name="delete-account"),
    path("admin/dashboard/", AdminDashboardView.as_view(), name="admin-dashboard"),
    path("admin/reports/", AdminReportView.as_view(), name="admin-reports"),
    path("admin/users/create/", AdminCreateUserView.as_view(), name="admin-create-user"),
    path("water/today/", TodayWaterView.as_view(), name="today-water"),
    path("", include(router.urls)),
]
