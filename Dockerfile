FROM wordpress:php8.4-fpm-alpine

# Cài thêm bcmath, intl, exif, zip (WooCommerce rất cần mấy cái này)
RUN apk add --no-cache $PHPIZE_DEPS icu-dev libzip-dev \
    && pecl install redis \
    && docker-php-ext-enable redis \
    && docker-php-ext-configure intl \
    && docker-php-ext-install \
        bcmath \
        intl \
        exif \
        zip \
        opcache \
    && apk del --no-cache $PHPIZE_DEPS icu-dev libzip-dev

COPY docker-entrypoint-custom.sh /usr/local/bin/docker-entrypoint-custom.sh
RUN chmod +x /usr/local/bin/docker-entrypoint-custom.sh

ENTRYPOINT ["docker-entrypoint-custom.sh"]
CMD ["php-fpm"]
