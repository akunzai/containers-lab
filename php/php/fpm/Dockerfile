FROM php:7.0-fpm-alpine
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8
RUN set -ex; \
  apk add --update freetype \
    libjpeg-turbo libmcrypt libpng \
    icu libxml2 libxslt; \
  apk add --virtual .build-deps autoconf g++ make \
    freetype-dev libpng-dev libjpeg-turbo-dev libmcrypt-dev \
    icu-dev libxml2-dev libxslt-dev; \
  # Install PHP Extensions
  docker-php-ext-install -j$(getconf _NPROCESSORS_ONLN) \
    gd mbstring mcrypt mysqli opcache zip \
    intl pcntl pdo_mysql soap xsl; \
  # Install PECL Extensions
  echo no | pecl install xdebug redis; \
  docker-php-ext-enable xdebug redis; \
  rm -rf /tmp/pear; \
  # Cleanup
  apk del .build-deps; \
  rm -rf /var/cache/apk/*