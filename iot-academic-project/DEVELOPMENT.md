# Developer Guide

This document explains what has already been done and what each developer must do
to work on the IoT academic project.

## Repository

- GitHub: <https://github.com/Ayoub-27764101/mobile-Lab>
- Project folder: `iot-academic-project/`
- Main branch: `main`
- Backend: Symfony 7.4 / PHP 8.4
- Database: PostgreSQL 18
- Mobile: Flutter
- Firmware: ESP32 / PlatformIO

## 1. What DevOps has already done

- Created the monorepo structure: `backend/`, `mobile/`, `firmware/`,
  `infrastructure/`, `docs/`.
- Installed the Symfony 7.4 application in `backend/`.
- Added `backend/Dockerfile` with PHP 8.4, Apache, Composer, and the
  `pdo_pgsql` / `intl` / `opcache` extensions.
- Configured Apache to serve Symfony from `backend/public/`.
- Added `docker-compose.yml` with the Symfony backend and PostgreSQL 18.
- Configured a PostgreSQL healthcheck and made the backend wait for the database.
- Fixed the PostgreSQL 18 data volume path (`/var/lib/postgresql`).
- Added `backend/.env` with `APP_ENV`, `APP_SECRET`, `DEFAULT_URI`, and
  `DATABASE_URL`.
- Added a minimal ESP32 PlatformIO project in `firmware/`.
- Added CI workflows in the repository root `.github/workflows/`:
  - `backend-ci.yml`
  - `mobile-ci.yml`
  - `firmware-ci.yml`
- Updated all workflow paths to use `iot-academic-project/...`.
- Verified that both containers start and that Symfony responds on port `8080`.
- Pushed the scaffold to GitHub:
  - `ac25e9d` - Add IoT academic project scaffold
  - `adad3c7` - Move IoT CI workflows to repository root

### Not done yet (DevOps backlog)

- Branch protection on `main`.
- Production/staging deployment.
- Real Terraform infrastructure.
- Database backups and restore tests.
- Monitoring, logging, and uptime alerts.
- Container image publishing (GHCR).
- Production secrets management.

## 2. What every developer must do first

### Prerequisites

- Git
- Docker and Docker Compose

Optional depending on your task:

- PHP 8.4 + Composer (for host-side Composer/Symfony commands)
- Flutter SDK (mobile)
- PlatformIO (firmware)

### Clone the repository

```bash
git clone https://github.com/Ayoub-27764101/mobile-Lab.git
cd mobile-Lab/iot-academic-project
```

### Start the stack

```bash
docker compose up -d --build
```

### Install backend dependencies (required after cloning)

`backend/vendor/` is not committed, so run Composer once after the containers
are up:

```bash
docker compose exec backend composer install
```

If the command creates root-owned files and you cannot edit them locally:

```bash
sudo chown -R "$(id -u):$(id -g)" backend/vendor backend/var
```

### Verify

```bash
docker compose ps
curl -I http://localhost:8080
```

`docker compose ps` should show the backend as `Up` and PostgreSQL as `healthy`.
A `404` from `curl` is normal until API routes are added; the Symfony welcome
page is returned.

## 3. Backend development (Symfony API)

Work inside `backend/`.

### Install Doctrine ORM and migrations

```bash
docker compose exec backend composer require symfony/orm-pack
docker compose exec backend composer require --dev symfony/maker-bundle
```

`backend/.env` already contains:

```dotenv
DATABASE_URL="postgresql://symfony:symfony_password@db:5432/app_db?serverVersion=18&charset=utf8"
```

Inside Docker the database host is `db`, not `localhost`.

### Create the first entity and migration

```bash
docker compose exec backend php bin/console make:entity SensorReading
docker compose exec backend php bin/console make:migration
docker compose exec backend php bin/console doctrine:migrations:migrate --no-interaction
```

### Create an API controller

```bash
docker compose exec backend php bin/console make:controller Api/SensorReadingController
```

Recommended conventions:

- Prefix all API routes with `/api`.
- Return JSON responses.
- Use HTTP status codes correctly (`200`, `201`, `400`, `404`, `500`).
- Validate incoming ESP32 payloads before saving them.
- Add a simple `GET /api/health` endpoint for deployment smoke tests.

### Useful backend commands

```bash
docker compose exec backend php bin/console
docker compose exec backend php bin/console cache:clear
docker compose exec backend php bin/console debug:router
docker compose exec backend php bin/console doctrine:schema:validate
```

### Tests and static analysis (optional)

The CI workflow runs PHPStan and PHPUnit only if they are installed:

```bash
docker compose exec backend composer require --dev phpstan/phpstan phpunit/phpunit
```

Then run:

```bash
docker compose exec backend vendor/bin/phpstan analyse
docker compose exec backend vendor/bin/phpunit
```

## 4. Database

Connect to PostgreSQL:

```bash
docker compose exec db psql -U symfony -d app_db
```

Local defaults:

- User: `symfony`
- Password: `symfony_password`
- Database: `app_db`
- Host port: `5432`

These credentials are for local development only. Do not reuse them in
production.

## 5. Mobile development (Flutter)

The `mobile/` folder is currently empty except for `.gitkeep`. Initialize the
Flutter application once:

```bash
cd mobile
flutter create .
flutter pub get
flutter run
```

Then commit the generated project files (but not `build/`).

The mobile CI workflow runs `flutter pub get`, `flutter analyze`, `flutter test`,
and `flutter build apk --debug` when files under `iot-academic-project/mobile/`
change.

## 6. Firmware development (ESP32)

The `firmware/` folder contains a minimal PlatformIO project:

```bash
cd firmware
pio run
pio run -t upload
pio device monitor
```

The firmware should send sensor data to the Symfony API using HTTP POST.

## 7. Git workflow

Do not work directly on `main`. Use a feature branch and a pull request:

```bash
git checkout main
git pull
git checkout -b feature/my-change

# make changes
git add <files>
git commit -m "feat(api): describe the change"
git push -u origin feature/my-change
```

Then open a Pull Request on GitHub.

Rules:

- Do not commit `vendor/`, `var/`, `build/`, or `.pio/`.
- Do not commit real secrets, tokens, or production passwords.
- Use `backend/.env.local` for local overrides; it is git-ignored.
- Do not run `setup_devops.sh` inside this project. It is the scaffolding script
  and would create another nested `iot-academic-project/` directory.

## 8. CI (GitHub Actions)

Workflows are in the repository root `.github/workflows/`:

- `backend-ci.yml` triggers on `iot-academic-project/backend/**`
- `mobile-ci.yml` triggers on `iot-academic-project/mobile/**`
- `firmware-ci.yml` triggers on `iot-academic-project/firmware/**`

Backend CI runs Composer install and, when installed, PHPStan and PHPUnit.
Firmware CI compiles the PlatformIO project. Mobile CI requires the Flutter
project to exist first.

## 9. Secrets and configuration

Committed development defaults are in `backend/.env`.

For anything real:

- Use GitHub Environment Secrets for CI/deployment.
- Use `backend/.env.local` locally.
- Never commit production database passwords, API keys, or SSH keys.
- Change `APP_SECRET` for production.

## 10. Troubleshooting

### `Environment variable not found: "DEFAULT_URI"`

Ensure `backend/.env` contains:

```dotenv
DEFAULT_URI=http://localhost:8080
```

### `vendor/autoload.php` not found

Run:

```bash
docker compose exec backend composer install
```

### Port already in use

Change the host port in `docker-compose.yml`:

```yaml
ports:
  - "8081:80"
```

Then use `http://localhost:8081`.

### Clear the Symfony cache

```bash
docker compose exec backend php bin/console cache:clear
```

### Reset the containers

```bash
docker compose down
docker compose up -d --build
```

To also delete the database volume (destructive):

```bash
docker compose down -v
```

## 11. Recommended first tasks

1. Add `GET /api/health`.
2. Add Doctrine entity/entities for sensor readings.
3. Add ESP32 POST endpoint and validation.
4. Add Flutter app initialization.
5. Add tests and enable the CI checks.
6. Configure branch protection on `main`.
