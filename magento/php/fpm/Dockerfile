FROM php:7.2-fpm-alpine
RUN set -ex; \
  apk add --update freetype \
    libjpeg-turbo libmcrypt libpng \
    icu libxml2 libxslt; \
  apk add --virtual .build-deps autoconf g++ make \
    freetype-dev libpng-dev libjpeg-turbo-dev libmcrypt-dev \
    icu-dev libxml2-dev libxslt-dev; \
  # Install PHP Extensions
  docker-php-ext-install -j$(getconf _NPROCESSORS_ONLN) \
    gd mbstring mysqli opcache zip \
    intl pcntl pdo_mysql soap xsl; \
  # Install PECL Extensions
  echo no | pecl install mcrypt-1.0.1 redis xdebug; \
  docker-php-ext-enable mcrypt redis xdebug; \
  rm -rf /tmp/pear; \
  # Cleanup
  apk del .build-deps; \
  rm -rf /var/cache/apk/*