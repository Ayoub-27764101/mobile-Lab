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
- `.github/workflows/` - CI pipelines (at the repository root)

## Developer Guide
Read [DEVELOPMENT.md](DEVELOPMENT.md) for the complete developer workflow,
what DevOps has already configured, and the remaining tasks.

## Quick Start
```bash
# From the repository root
cd iot-academic-project

docker compose up -d --build
docker compose exec backend composer install
```

The API is available at http://localhost:8080. A `404` is expected until API
routes are added.

Stop the stack with:

```bash
docker compose down
```

## Database Credentials
Local development defaults:

- User: `symfony`
- Password: `symfony_password`
- Database: `app_db`

Override them with the `POSTGRES_USER`, `POSTGRES_PASSWORD`, and `POSTGRES_DB`
environment variables when running Docker Compose. These credentials are for
local development only.

## CI
GitHub Actions runs the backend, mobile, and firmware pipelines when the matching
paths under `iot-academic-project/` change. Backend static analysis and tests are
skipped until PHPStan/PHPUnit are installed in `backend/vendor`.
