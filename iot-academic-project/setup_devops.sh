#!/bin/bash

# ==========================================
# DevOps Scaffolding Script for IoT Project
# Stack: ESP32, Symfony 7.4, PHP 8.4, Postgres 18, Flutter
# ==========================================

set -euo pipefail # Exit on error, undefined variables, and failed pipes.

PROJECT_NAME="iot-academic-project"
echo "🚀 Setting up DevOps scaffolding for $PROJECT_NAME..."

# 1. Create Monorepo Folder Structure
echo "📁 Creating folder structure..."
mkdir -p "$PROJECT_NAME"/{backend,mobile,firmware/src,infrastructure,docs,.github/workflows}
cd "$PROJECT_NAME"

# 2. Initialize Git
echo "🔧 Initializing Git repository..."
if [ ! -d .git ]; then
  git init -b main
fi

# 3. Create .gitignore
echo "📝 Creating .gitignore..."
cat << 'EOF' > .gitignore
# Environment variables (keep committed defaults, ignore local overrides)
.env.local
.env.*.local

# IDE
.idea/
.vscode/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Docker volumes
db_data/

# Build artifacts
backend/var/
backend/vendor/
mobile/build/
firmware/.pio/
EOF

# 4. Backend (Symfony 7.4 / PHP 8.4) Scaffolding
echo "🐘 Setting up Backend (Symfony 7.4 / PHP 8.4) DevOps files..."
cat << 'EOF' > backend/Dockerfile
# Use official PHP 8.4 image with Apache
FROM php:8.4-apache

# Install system dependencies and PHP extensions for Symfony/Postgres 18
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    unzip \
    libpq-dev \
    libicu-dev \
    && docker-php-ext-install intl opcache pdo pdo_pgsql \
    && rm -rf /var/lib/apt/lists/*

# Enable Apache mod_rewrite (Required for Symfony routing)
RUN a2enmod rewrite

# Point Apache at Symfony's public directory
ENV APACHE_DOCUMENT_ROOT=/var/www/html/public
RUN sed -ri -e "s!/var/www/html!${APACHE_DOCUMENT_ROOT}!g" /etc/apache2/sites-available/*.conf \
    && sed -ri -e "s!/var/www/!${APACHE_DOCUMENT_ROOT}!g" /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf \
    && sed -ri -e "s/AllowOverride None/AllowOverride All/g" /etc/apache2/apache2.conf

# Set working directory
WORKDIR /var/www/html

# Install Composer
COPY --from=composer:2.8 /usr/bin/composer /usr/bin/composer

# Copy project files
COPY . .

# Install dependencies (Uncomment when composer.json exists)
# RUN composer install --no-dev --optimize-autoloader

# Expose port 80
EXPOSE 80
EOF

cat << 'EOF' > backend/.dockerignore
vendor/
var/
.env.local
.env.*.local
EOF

cat << 'EOF' > backend/.env
# Symfony 7.4 Environment Variables
APP_ENV=dev
APP_SECRET=change_me_in_production
DEFAULT_URI=http://localhost:8080
# Note: serverVersion must match your Postgres major version (18)
DATABASE_URL="postgresql://symfony:symfony_password@db:5432/app_db?serverVersion=18&charset=utf8"
EOF

# 5. Docker Compose (Local Development)
echo "🐳 Creating docker-compose.yml..."
cat << 'EOF' > docker-compose.yml
services:
  db:
    image: postgres:18-alpine
    environment:
      POSTGRES_USER: ${POSTGRES_USER:-symfony}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-symfony_password}
      POSTGRES_DB: ${POSTGRES_DB:-app_db}
    ports:
      - "5432:5432" # Exposed to host for local debugging
    volumes:
      # Postgres 18 moved its data volume to /var/lib/postgresql
      - db_data:/var/lib/postgresql
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER:-symfony} -d ${POSTGRES_DB:-app_db}"]
      interval: 5s
      timeout: 5s
      retries: 10
    networks:
      - iot_network

  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    ports:
      - "8080:80" # Access Symfony at http://localhost:8080
    environment:
      DATABASE_URL: "postgresql://${POSTGRES_USER:-symfony}:${POSTGRES_PASSWORD:-symfony_password}@db:5432/${POSTGRES_DB:-app_db}?serverVersion=18&charset=utf8"
    depends_on:
      db:
        condition: service_healthy
    volumes:
      - ./backend:/var/www/html # Hot-reloading for local dev
    networks:
      - iot_network

volumes:
  db_data:

networks:
  iot_network:
    driver: bridge
EOF

# 6. Firmware (ESP32 / PlatformIO) Scaffolding
echo "🔌 Creating firmware PlatformIO project..."
cat << 'EOF' > firmware/platformio.ini
[env:esp32dev]
platform = espressif32
board = esp32dev
framework = arduino
monitor_speed = 115200
EOF

cat << 'EOF' > firmware/src/main.cpp
#include <Arduino.h>

void setup() {
  Serial.begin(115200);
}

void loop() {
  delay(1000);
}
EOF

# 7. GitHub Actions CI Workflows
echo "⚙️ Creating GitHub Actions CI pipelines..."

# Backend CI (Updated for PHP 8.4)
cat << 'EOF' > .github/workflows/backend-ci.yml
name: Backend CI (Symfony 7.4 / PHP 8.4)
on:
  push:
    paths:
      - 'backend/**'
  pull_request:
    paths:
      - 'backend/**'

jobs:
  build-and-test:
    runs-on: ubuntu-latest
    env:
      APP_ENV: test
      DATABASE_URL: "postgresql://symfony:symfony_password@127.0.0.1:5432/app_db?serverVersion=18&charset=utf8"
    services:
      postgres:
        image: postgres:18-alpine
        env:
          POSTGRES_USER: symfony
          POSTGRES_PASSWORD: symfony_password
          POSTGRES_DB: app_db
        ports:
          - 5432:5432
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
    steps:
      - uses: actions/checkout@v4
      - name: Setup PHP 8.4
        uses: shivammathur/setup-php@v2
        with:
          php-version: '8.4'
          extensions: pdo_pgsql, intl
      - name: Install Dependencies
        run: composer install --prefer-dist --no-progress --no-interaction
        working-directory: ./backend
      - name: Run Static Analysis (PHPStan)
        if: ${{ hashFiles('backend/vendor/bin/phpstan') != '' }}
        run: vendor/bin/phpstan analyse
        working-directory: ./backend
      - name: Run Tests (PHPUnit)
        if: ${{ hashFiles('backend/vendor/bin/phpunit') != '' }}
        run: vendor/bin/phpunit
        working-directory: ./backend
EOF

# Mobile CI
cat << 'EOF' > .github/workflows/mobile-ci.yml
name: Mobile CI (Flutter)
on:
  push:
    paths:
      - 'mobile/**'
  pull_request:
    paths:
      - 'mobile/**'

jobs:
  build-and-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          channel: 'stable'
          cache: true
      - name: Get Dependencies
        run: flutter pub get
        working-directory: ./mobile
      - name: Analyze Code
        run: flutter analyze
        working-directory: ./mobile
      - name: Run Tests
        run: flutter test
        working-directory: ./mobile
      - name: Build APK
        run: flutter build apk --debug
        working-directory: ./mobile
EOF

# Firmware CI
cat << 'EOF' > .github/workflows/firmware-ci.yml
name: Firmware CI (ESP32)
on:
  push:
    paths:
      - 'firmware/**'
  pull_request:
    paths:
      - 'firmware/**'

jobs:
  compile:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.11'
      - name: Install PlatformIO
        run: pip install platformio
      - name: Compile ESP32 Firmware
        run: pio run
        working-directory: ./firmware
EOF

# 8. Infrastructure & Docs Placeholders
echo "📄 Creating Infrastructure and Docs placeholders..."
cat << 'EOF' > infrastructure/main.tf
# Terraform placeholder
# Add your AWS/DigitalOcean/Hetzner VM provisioning code here.
EOF

cat << 'EOF' > docs/architecture.md
# Architecture Diagram

## Data Flow
1. **ESP32** reads sensors and sends HTTP POST requests to the Symfony 7.4 API.
2. **Symfony API** validates the payload and saves it to **PostgreSQL 18**.
3. **Flutter App** sends HTTP GET requests to the Symfony API to display data.

## Network Diagram
[Insert draw.io or Lucidchart diagram here before submission]
EOF

# 9. README.md (Using README_EOF to prevent delimiter collision)
echo "📖 Creating README.md..."
cat << 'README_EOF' > README.md
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
README_EOF
