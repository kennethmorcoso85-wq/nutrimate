import re

from django.core import mail
from django.test import override_settings
from django.contrib.auth import get_user_model
from rest_framework.test import APITestCase

from .models import AuditEvent, EducationArticle, FoodCategory, MealRecord


User = get_user_model()


class ApiWorkflowTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            email="user@example.com",
            name="Test User",
            password="StrongPass123!",
        )
        self.admin = User.objects.create_superuser(
            email="nutrimate@admin.com",
            name="Test Admin",
            password="StrongPass123!",
        )
        self.category = FoodCategory.objects.create(name="Fruits")

    def test_protected_api_requires_authentication_in_development(self):
        dashboard = self.client.get("/api/v1/admin/dashboard/")
        self.assertEqual(dashboard.status_code, 401)
        meals = self.client.get("/api/v1/meals/")
        self.assertEqual(meals.status_code, 401)
        created = self.client.post(
            "/api/v1/meals/",
            {
                "name": "Oatmeal",
                "category": "Breakfast",
                "calories": 150,
                "protein": 5,
                "carbs": 27,
                "fat": 3,
            },
        )
        self.assertEqual(created.status_code, 401)

    def authenticate(self, user):
        response = self.client.post(
            "/api/v1/auth/token/",
            {"email": user.email, "password": "StrongPass123!"},
        )
        self.assertEqual(response.status_code, 200)
        self.client.credentials(
            HTTP_AUTHORIZATION=f"Bearer {response.data['access']}"
        )

    def test_registration_never_assigns_admin_role(self):
        response = self.client.post(
            "/api/v1/auth/register/",
            {
                "name": "New User",
                "email": "new@example.com",
                "password": "SafePassword123!",
                "role": "admin",
            },
        )
        self.assertEqual(response.status_code, 201)
        created = User.objects.get(email="new@example.com")
        self.assertEqual(created.role, User.Role.USER)
        self.assertNotIn("password", response.data)

    def test_user_can_only_read_and_write_own_meals(self):
        self.authenticate(self.user)
        created = self.client.post(
            "/api/v1/meals/",
            {
                "name": "Oatmeal",
                "category": "Breakfast",
                "calories": 150,
                "protein": 5,
                "carbs": 27,
                "fat": 3,
                "notes": "private note",
            },
        )
        self.assertEqual(created.status_code, 201)
        self.assertEqual(self.client.get("/api/v1/meals/").data[0]["name"], "Oatmeal")
        updated = self.client.patch(
            f"/api/v1/meals/{created.data['id']}/",
            {"name": "Overnight oats"},
            format="json",
        )
        self.assertEqual(updated.status_code, 200)
        self.assertEqual(updated.data["name"], "Overnight oats")

        other = User.objects.create_user(
            email="other@example.com", name="Other", password="StrongPass123!"
        )
        self.client.force_authenticate(user=other)
        self.assertEqual(self.client.get("/api/v1/meals/").data, [])
        self.assertEqual(
            self.client.patch(
                f"/api/v1/meals/{created.data['id']}/",
                {"name": "Not yours"},
                format="json",
            ).status_code,
            404,
        )

    def test_admin_dashboard_is_for_admins_only(self):
        self.authenticate(self.user)
        self.assertEqual(self.client.get("/api/v1/admin/dashboard/").status_code, 403)
        self.authenticate(self.admin)
        response = self.client.get("/api/v1/admin/dashboard/")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["registered_accounts"], 2)

    def test_food_catalog_is_admin_managed_and_users_see_published_records_only(self):
        self.authenticate(self.user)
        denied = self.client.post(
            "/api/v1/foods/",
            {"name": "Banana", "category": self.category.id},
        )
        self.assertEqual(denied.status_code, 403)

        self.authenticate(self.admin)
        created = self.client.post(
            "/api/v1/foods/",
            {
                "name": "Banana",
                "barcode": "1234567890123",
                "category": self.category.id,
                "serving_size": "100",
                "serving_unit": "g",
                "calories": 89,
                "protein": "1.10",
                "carbs": "22.80",
                "fat": "0.30",
                "status": "published",
            },
        )
        self.assertEqual(created.status_code, 201)
        self.authenticate(self.user)
        self.assertEqual(len(self.client.get("/api/v1/foods/").data), 1)
        self.assertEqual(
            len(self.client.get("/api/v1/foods/?barcode=1234567890123").data),
            1,
        )
        self.assertEqual(
            self.client.get("/api/v1/foods/?barcode=0000000000000").data,
            [],
        )

    def test_food_meal_nutrients_are_calculated_from_published_catalog(self):
        self.authenticate(self.admin)
        food = self.client.post(
            "/api/v1/foods/",
            {
                "name": "Banana",
                "category": self.category.id,
                "serving_size": "100",
                "serving_unit": "g",
                "calories": 89,
                "protein": "1.10",
                "carbs": "22.80",
                "fat": "0.30",
                "status": "published",
            },
            format="json",
        )
        self.assertEqual(food.status_code, 201)

        self.authenticate(self.user)
        logged = self.client.post(
            "/api/v1/meals/",
            {
                "food": food.data["id"],
                "servings": "1.50",
                "name": "Forged name",
                "category": "Breakfast",
                "calories": 9999,
                "protein": 999,
                "carbs": 999,
                "fat": 999,
            },
            format="json",
        )
        self.assertEqual(logged.status_code, 201)
        self.assertEqual(logged.data["name"], "Banana")
        self.assertEqual(logged.data["calories"], 134)
        self.assertEqual(logged.data["protein"], 2)
        self.assertEqual(logged.data["carbs"], 34)
        self.assertEqual(logged.data["fat"], 0)
        self.assertEqual(logged.data["servings"], "1.50")

        updated = self.client.patch(
            f"/api/v1/meals/{logged.data['id']}/",
            {"calories": 1, "protein": 1},
            format="json",
        )
        self.assertEqual(updated.status_code, 200)
        self.assertEqual(updated.data["calories"], 134)
        self.assertEqual(updated.data["protein"], 2)

        invalid_servings = self.client.post(
            "/api/v1/meals/",
            {
                "food": food.data["id"],
                "servings": "0",
                "name": "Banana",
                "category": "Breakfast",
                "calories": 89,
                "protein": 1,
                "carbs": 23,
                "fat": 0,
            },
            format="json",
        )
        self.assertEqual(invalid_servings.status_code, 400)

        self.authenticate(self.admin)
        draft = self.client.post(
            "/api/v1/foods/",
            {
                "name": "Draft food",
                "category": self.category.id,
                "status": "draft",
            },
            format="json",
        )
        self.assertEqual(draft.status_code, 201)
        self.authenticate(self.user)
        unpublished_food = self.client.post(
            "/api/v1/meals/",
            {
                "food": draft.data["id"],
                "servings": "1",
                "name": "Draft food",
                "category": "Breakfast",
                "calories": 10,
                "protein": 1,
                "carbs": 1,
                "fat": 1,
            },
            format="json",
        )
        self.assertEqual(unpublished_food.status_code, 400)

    def test_user_water_is_scoped_and_validated(self):
        self.authenticate(self.user)
        saved = self.client.put("/api/v1/water/today/", {"amount_ml": 750})
        self.assertEqual(saved.status_code, 200)
        self.assertEqual(saved.data["amount_ml"], 750)
        invalid = self.client.put("/api/v1/water/today/", {"amount_ml": 20000})
        self.assertEqual(invalid.status_code, 400)

    def test_admin_can_create_and_deactivate_user_but_user_cannot_manage_accounts(self):
        self.authenticate(self.user)
        denied = self.client.get("/api/v1/admin/users/")
        self.assertEqual(denied.status_code, 403)

        self.authenticate(self.admin)
        created = self.client.post(
            "/api/v1/admin/users/create/",
            {
                "name": "Managed User",
                "email": "managed@example.com",
                "password": "ManagedPassword123!",
            },
        )
        self.assertEqual(created.status_code, 201)
        managed = User.objects.get(email="managed@example.com")
        self.assertEqual(managed.role, User.Role.USER)
        self.assertFalse(managed.is_staff)
        response = self.client.patch(
            f"/api/v1/admin/users/{managed.pk}/",
            {"is_active": False},
            format="json",
        )
        self.assertEqual(response.status_code, 200)
        managed.refresh_from_db()
        self.assertFalse(managed.is_active)

    def test_django_admin_user_add_form_supports_email_username_model(self):
        self.client.force_login(self.admin)
        response = self.client.get("/django-admin/api/user/add/")
        self.assertEqual(response.status_code, 200)

    def test_profile_preferences_and_account_export_are_user_scoped(self):
        self.client.force_authenticate(user=self.user)
        updated = self.client.patch(
            "/api/v1/auth/me/",
            {
                "name": "Updated User",
                "preferences": {
                    "units": "Imperial",
                    "water_reminders": True,
                    "nutrition_goals": {"calories": 2000},
                },
            },
            format="json",
        )
        self.assertEqual(updated.status_code, 200)
        self.assertEqual(updated.data["preferences"]["units"], "Imperial")

        MealRecord.objects.create(
            user=self.user,
            name="Oatmeal",
            category="Breakfast",
            calories=150,
            protein=5,
            carbs=27,
            fat=3,
        )
        export = self.client.get("/api/v1/auth/export/")
        self.assertEqual(export.status_code, 200)
        self.assertEqual(len(export.data["meals"]), 1)

        self.client.force_authenticate(user=self.admin)
        self.assertEqual(self.client.get("/api/v1/auth/export/").data["meals"], [])

    def test_account_password_change_and_deletion_require_current_password(self):
        self.client.force_authenticate(user=self.user)
        denied = self.client.post(
            "/api/v1/auth/change-password/",
            {
                "current_password": "wrong-password",
                "new_password": "NewStrongPass456!",
            },
            format="json",
        )
        self.assertEqual(denied.status_code, 400)
        changed = self.client.post(
            "/api/v1/auth/change-password/",
            {
                "current_password": "StrongPass123!",
                "new_password": "NewStrongPass456!",
            },
            format="json",
        )
        self.assertEqual(changed.status_code, 204)
        self.user.refresh_from_db()
        self.assertTrue(self.user.check_password("NewStrongPass456!"))

        denied_delete = self.client.delete(
            "/api/v1/auth/account/",
            {"password": "wrong-password"},
            format="json",
        )
        self.assertEqual(denied_delete.status_code, 400)
        deleted = self.client.delete(
            "/api/v1/auth/account/",
            {"password": "NewStrongPass456!"},
            format="json",
        )
        self.assertEqual(deleted.status_code, 204)
        self.assertFalse(User.objects.filter(pk=self.user.pk).exists())
        self.assertTrue(
            AuditEvent.objects.filter(action="account.deleted").exists()
        )

    @override_settings(
        EMAIL_BACKEND="django.core.mail.backends.locmem.EmailBackend",
        DEFAULT_FROM_EMAIL="noreply@example.com",
    )
    def test_email_verification_and_password_reset_codes_are_one_time(self):
        self.client.force_authenticate(user=self.user)
        requested = self.client.post("/api/v1/auth/email/verification/request/")
        self.assertEqual(requested.status_code, 200)
        code = re.search(r"\b\d{6}\b", mail.outbox[-1].body).group()
        verified = self.client.post(
            "/api/v1/auth/email/verification/confirm/",
            {"code": code},
            format="json",
        )
        self.assertEqual(verified.status_code, 200)
        self.assertTrue(verified.data["is_email_verified"])
        reused = self.client.post(
            "/api/v1/auth/email/verification/confirm/",
            {"code": code},
            format="json",
        )
        self.assertEqual(reused.status_code, 400)

        reset = self.client.post(
            "/api/v1/auth/password/reset/request/",
            {"email": self.user.email},
            format="json",
        )
        self.assertEqual(reset.status_code, 200)
        reset_code = re.search(r"\b\d{6}\b", mail.outbox[-1].body).group()
        confirmed = self.client.post(
            "/api/v1/auth/password/reset/confirm/",
            {
                "email": self.user.email,
                "code": reset_code,
                "new_password": "ResetStrongPass456!",
            },
            format="json",
        )
        self.assertEqual(confirmed.status_code, 204)
        self.user.refresh_from_db()
        self.assertTrue(self.user.check_password("ResetStrongPass456!"))

    def test_admin_content_announcements_and_audit_are_connected(self):
        self.client.force_authenticate(user=self.admin)
        article = self.client.post(
            "/api/v1/content/",
            {
                "title": "Nutrition basics",
                "summary": "A balanced overview",
                "category": "Nutrition",
                "body": "Eat a variety of foods.",
                "is_published": True,
            },
            format="json",
        )
        self.assertEqual(article.status_code, 201)
        self.client.force_authenticate(user=self.user)
        self.assertEqual(len(self.client.get("/api/v1/content/").data), 1)
        self.assertEqual(
            self.client.post(
                "/api/v1/content/",
                {
                    "title": "Blocked",
                    "summary": "No",
                    "category": "Nutrition",
                    "body": "No",
                    "is_published": True,
                },
                format="json",
            ).status_code,
            403,
        )

        self.client.force_authenticate(user=self.admin)
        announcement = self.client.post(
            "/api/v1/announcements/",
            {"title": "Update", "body": "New catalog items are available."},
            format="json",
        )
        self.assertEqual(announcement.status_code, 201)
        self.client.force_authenticate(user=self.user)
        self.assertEqual(len(self.client.get("/api/v1/announcements/").data), 1)
        self.client.force_authenticate(user=self.admin)
        self.assertGreaterEqual(
            len(self.client.get("/api/v1/admin/audit/").data),
            2,
        )

    def test_admin_report_is_date_filtered_and_aggregate_only(self):
        self.client.force_authenticate(user=self.user)
        MealRecord.objects.create(
            user=self.user,
            name="Private meal",
            category="Lunch",
            calories=300,
            protein=10,
            carbs=30,
            fat=8,
        )
        self.client.force_authenticate(user=self.admin)
        response = self.client.get("/api/v1/admin/reports/")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["meal_records"], 1)
        self.assertNotIn("meals", response.data)
        self.assertEqual(
            self.client.get(
                "/api/v1/admin/reports/?start=not-a-date"
            ).status_code,
            400,
        )

    def test_water_entries_persist_and_keep_daily_total_in_sync(self):
        self.client.force_authenticate(user=self.user)
        created = self.client.post(
            "/api/v1/water/entries/",
            {"amount_ml": 300},
            format="json",
        )
        self.assertEqual(created.status_code, 201)
        self.assertEqual(
            self.client.get("/api/v1/water/today/").data["amount_ml"],
            300,
        )

        updated = self.client.patch(
            f"/api/v1/water/entries/{created.data['id']}/",
            {"amount_ml": 450},
            format="json",
        )
        self.assertEqual(updated.status_code, 200)
        self.assertEqual(
            self.client.get("/api/v1/water/today/").data["amount_ml"],
            450,
        )

        other = User.objects.create_user(
            email="other-water@example.com",
            name="Other",
            password="StrongPass123!",
        )
        self.client.force_authenticate(user=other)
        self.assertEqual(self.client.get("/api/v1/water/entries/").data, [])
        self.assertEqual(
            self.client.delete(
                f"/api/v1/water/entries/{created.data['id']}/"
            ).status_code,
            404,
        )

        self.client.force_authenticate(user=self.user)
        deleted = self.client.delete(
            f"/api/v1/water/entries/{created.data['id']}/"
        )
        self.assertEqual(deleted.status_code, 204)
        self.assertEqual(
            self.client.get("/api/v1/water/today/").data["amount_ml"],
            0,
        )

    def test_measurements_are_persisted_and_private_per_account(self):
        self.client.force_authenticate(user=self.user)
        created = self.client.post(
            "/api/v1/measurements/",
            {"weight_kg": "62.50", "height_cm": "168.00"},
            format="json",
        )
        self.assertEqual(created.status_code, 201)
        self.assertEqual(created.data["weight_kg"], "62.50")

        other = User.objects.create_user(
            email="other-measurement@example.com",
            name="Other",
            password="StrongPass123!",
        )
        self.client.force_authenticate(user=other)
        self.assertEqual(self.client.get("/api/v1/measurements/").data, [])
        self.assertEqual(
            self.client.get(
                f"/api/v1/measurements/{created.data['id']}/"
            ).status_code,
            404,
        )

        self.client.force_authenticate(user=self.user)
        invalid = self.client.post(
            "/api/v1/measurements/",
            {"weight_kg": "600"},
            format="json",
        )
        self.assertEqual(invalid.status_code, 400)
