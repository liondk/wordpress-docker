FROM wordpress:php8.4-fpm
RUN pecl install redis && docker-php-ext-enable redis
