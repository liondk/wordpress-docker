FROM wordpress:php8.4-fpm-alpine

RUN apk add --no-cache $PHPIZE_DEPS \
    && pecl install redis \
    && docker-php-ext-enable redis \
    && apk del --no-cache $PHPIZE_DEPS

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["php-fpm"]