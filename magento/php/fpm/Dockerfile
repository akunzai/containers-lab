FROM php:7.2-fpm
ENV LANG=C.UTF-8
RUN set -ex; \
  # ensure www-data userhome & permissions
  mkdir -p /var/www/html; \
  chown -R www-data:www-data /var/www; \
  # persistent / runtime deps
  apt-get update; \
  apt-get install -y --no-install-recommends \
    libfreetype6 libjpeg62-turbo libpng16-16 libicu57 libmcrypt4 libwebp6 libxml2 libxpm4 libxslt1.1; \
  # dependencies required for building
  buildDeps="libfreetype6-dev libjpeg-dev libpng-dev \
    libmcrypt-dev libicu-dev \
    libwebp-dev libxml2-dev libxpm-dev libxslt1-dev"; \
  apt-get install -y --no-install-recommends $buildDeps; \
  # install PHP Extensions
  docker-php-ext-configure gd \
    --with-freetype-dir=/usr/include/ \
    --with-jpeg-dir=/usr/include/ \
    --with-xpm-dir=/usr/include/ \
    --with-webp-dir=/usr/include/; \
  docker-php-ext-install -j$(nproc) \
    gd mysqli opcache zip \
    intl pcntl pdo_mysql soap xsl; \
  # install PECL Extensions
  echo no | pecl install mcrypt redis xdebug; \
  docker-php-ext-enable mcrypt redis xdebug; \
  rm -rf /tmp/pear; \
  # cleanup
  apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false $buildDeps; \
  rm -rf /var/lib/apt/lists/*