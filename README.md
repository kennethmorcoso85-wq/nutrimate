# NutriMate

NutriMate is a Flutter nutrition-tracking app connected to a Django REST API.
The backend uses SQLite and JWT authentication; its database is stored in
`backend/db.sqlite3` (see [backend/README.md](./backend/README.md)).

The current workspace contains the Flutter client and Django API; it does not
yet contain a React web client. Catalog-based meal entries are calculated by
the backend from published food data and serving quantities. Existing manual
meal entries remain supported.

## Start the backend

In PowerShell:

```powershell
cd backend
py -3.13 -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
python manage.py migrate
python manage.py createsuperuser --email nutrimate@admin.com --name "NutriMate Administrator"
python manage.py runserver 0.0.0.0:8000
```

The API defaults to `http://10.0.2.2:8000/api/v1/` for the Android emulator
and `http://127.0.0.1:8000/api/v1/` for Windows desktop, web, and iOS simulator.
For a physical Android phone on the same Wi-Fi, use the computer's LAN IP for
the Flutter API base URL and allow that IP in `DJANGO_ALLOWED_HOSTS` as
described in [backend/README.md](./backend/README.md). For other devices or
hosts, pass the API base URL when starting Flutter:

```powershell
flutter run --dart-define=NUTRIMATE_API_BASE_URL=http://YOUR_COMPUTER_LAN_IP:8000/api/v1/
```

Create the shared administrator once using `createsuperuser`; set its password
at the prompt, then use that same account for the Flutter Admin dashboard and
Django Admin. Public signup has no role selector and always creates a regular
User. The Admin workspace can then create User accounts,
activate/deactivate accounts, manage food categories and food records, publish
foods, and view aggregate dashboard statistics. Users can sign in and manage
their own meal and daily water records through the API.

## Current limitations

SQLite and the development server are for local development only. Set secure
deployment settings and use a production database before release. JWT tokens
are currently stored in app preferences; use platform-secure token storage for
a production mobile deployment. Change the supplied local admin password
before exposing the backend beyond local development. Server-persisted
nutrition goals and history summaries, body measurements, article publishing,
recommendation rules, delivered notifications, audit logging, administrative
reports/exports, password recovery, and a React web client are not implemented
yet. Food nutrition values require a verified source and are not medical
guidance.
