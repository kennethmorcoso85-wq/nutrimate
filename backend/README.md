# NutriMate Django REST API

Django REST API for the NutriMate Flutter app. The backend uses SQLite and
stores its database in `backend/db.sqlite3`.

## Setup

From this folder, create and activate a virtual environment, then install:

```powershell
py -3.13 -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
python manage.py migrate
python manage.py createsuperuser --email nutrimate@admin.com --name "NutriMate Administrator"
python manage.py runserver 0.0.0.0:8000
```

No database server or database credentials are required. Django reads and
writes the existing `backend/db.sqlite3` file. Migrations update its schema
without deleting the database or its records; back up this file before
applying migrations to important data.

Set the administrator password when prompted. Use this same account to sign in
to the Flutter Admin dashboard and to Django Admin at `/django-admin/`; do not
create an admin account through public signup. Public signup only creates
regular users, and the Admin dashboard's create-user feature also creates only
regular users.

The API is served under `/api/v1/`. The Flutter Android emulator uses
`http://10.0.2.2:8000/api/v1/`; Windows desktop, web, and iOS simulator use
`http://127.0.0.1:8000/api/v1/`.

For a physical phone on the same Wi-Fi, use the computer's LAN IPv4 address
(for example `192.168.1.7`) for the Flutter API URL and allow that host in
Django. In PowerShell, replace the example IP with the computer's current
address, then start the server:

```powershell
$env:DJANGO_ALLOWED_HOSTS = "127.0.0.1,localhost,10.0.2.2,192.168.1.7"
python manage.py runserver 0.0.0.0:8000
```

In another terminal, launch Flutter with the same IP:

```powershell
flutter run --dart-define=NUTRIMATE_API_BASE_URL=http://192.168.1.7:8000/api/v1/
```

The phone and computer must be on the same Wi-Fi, and Windows Firewall must
allow inbound TCP traffic on port `8000`. Set `NUTRIMATE_API_BASE_URL` at build
time to override the Flutter default.

## Available endpoints

- `GET /health/`
- `POST /auth/register/` (public registration always creates a User)
- `POST /admin/users/create/` (Admin creates a regular User account)
- `POST /auth/token/` and `POST /auth/token/refresh/` (JWT)
- `GET /auth/me/`
- `GET /admin/dashboard/`
- `GET /admin/users/`, `PATCH /admin/users/{id}/` (`is_active`)
- `GET|POST /categories/`, `GET|PATCH|DELETE /categories/{id}/`
- `GET|POST /foods/`, `GET|PATCH|DELETE /foods/{id}/`
- `GET|POST /meals/`, `GET|PATCH|DELETE /meals/{id}/`
- `GET|PUT /water/today/`

Food and category writes, dashboard stats, and user administration require a
server-authorized admin account. Create the shared administrator once with
`createsuperuser`. Users can only access their own meal and water records.
When a meal references a published catalog food and serving count, the API
calculates and stores its name, calories, and macros from the server-side food
record; client-submitted totals cannot override those calculations. Existing
manually logged meals remain supported for compatibility.

Protected API endpoints always require a valid JWT, including in development;
there is no implicit development user or authentication bypass.

`DEBUG` defaults to true for local development. Before deployment, configure a
unique `DJANGO_SECRET_KEY`, set `DJANGO_DEBUG=false`, and set
`DJANGO_ALLOWED_HOSTS` and `CORS_ALLOWED_ORIGINS`. SQLite is intended for local
development and small deployments; assess database concurrency and backup
requirements before using it in production. The supplied local admin password
is weak; change it before exposing the backend beyond local development.
