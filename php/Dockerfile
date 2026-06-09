FROM php:8.5-cli

RUN apt-get update && apt-get install -y --no-install-recommends \
        libzip-dev pkg-config \
    && rm -rf /var/cache/apt/archives/*

RUN pecl install redis \
    && docker-php-ext-enable redis

WORKDIR /app
CMD ["php", "/app/test-cluster.php"]

