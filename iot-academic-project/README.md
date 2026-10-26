# IoT Academic Project

## Tech Stack
- **Hardware:** ESP32
- **Backend:** Symfony 7.4 (PHP 8.4)
- **Database:** PostgreSQL 18
- **Mobile:** Flutter (Dart)

## Project Structure
- `backend/` - Symfony API
- `mobile/` - Flutter application
- `firmware/` - ESP32 PlatformIO project
- `infrastructure/` - Terraform (placeholder)
- `docs/` - Architecture documentation
- `.github/workflows/` - CI pipelines

## Local Development Setup

### Prerequisites
- Docker & Docker Compose installed.

### 1. Initialize Symfony Project (One-time setup)
Before running Docker, generate the Symfony 7.4 skeleton inside the backend folder:
```bash
# Run this on your host machine (requires PHP 8.4 and Composer installed locally)
composer create-project symfony/skeleton:"7.4.*" backend_temp --no-interaction
cp -an backend_temp/. backend/
rm -rf backend_temp

# Optional: install the tools used by CI
cd backend
composer require --dev phpstan/phpstan phpunit/phpunit --no-interaction
cd ..
```

### 2. Start the Stack
```bash
docker compose up -d --build
```
The API is available at http://localhost:8080.

### 3. Stop the Stack
```bash
docker compose down
```

### Database Credentials
The defaults are `symfony` / `symfony_password` and database `app_db`.
Override them with the `POSTGRES_USER`, `POSTGRES_PASSWORD`, and `POSTGRES_DB`
environment variables when running Docker Compose.

### CI
GitHub Actions runs the backend, mobile, and firmware pipelines on path changes.
Backend static analysis and tests are skipped until PHPStan/PHPUnit are installed
in `backend/vendor`.
