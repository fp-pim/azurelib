FROM php:7.0-alpine

RUN apk update

RUN apk add --no-cache curl
COPY --from=composer:2.2.18 /usr/bin/composer /usr/bin/composer

RUN apk add --no-cache pcre-dev $PHPIZE_DEPS

#RUN composer install
