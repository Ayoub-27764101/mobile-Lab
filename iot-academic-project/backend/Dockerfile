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
