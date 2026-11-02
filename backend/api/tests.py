from django.contrib.auth import get_user_model
from rest_framework.test import APITestCase

from .models import FoodCategory


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
