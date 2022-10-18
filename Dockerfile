FROM php:8.0-alpine

RUN apk update

RUN apk add --no-cache curl
COPY --from=composer:2.4.2 /usr/bin/composer /usr/bin/composer

RUN apk add --update --no-cache g++ gcc libxslt-dev
RUN apk add pcre-dev $PHPIZE_DEPS
RUN docker-php-ext-install xsl

#RUN composer install
