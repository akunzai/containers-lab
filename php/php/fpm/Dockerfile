FROM php:7.2-fpm
ENV LANG=C.UTF-8
RUN set -ex; \
  # ensure www-data userhome & permissions
  mkdir -p /var/www/html; \
  chown -R www-data:www-data /var/www; \
  # persistent / runtime deps
  apt-get update; \
  apt-get install -y --no-install-recommends \
    libfreetype6 libjpeg62-turbo libpng16-16 libicu57 libmcrypt4 libxml2 libxslt1.1; \
  # dependencies required for building
  buildDeps="libfreetype6-dev libjpeg62-turbo-dev libpng-dev \
    libmcrypt-dev libicu-dev \
    libxml2-dev libxslt1-dev"; \
  apt-get install -y --no-install-recommends $buildDeps; \
  # install PHP Extensions
  docker-php-ext-install -j$(nproc) \
    gd mysqli opcache zip \
    intl pcntl pdo_mysql soap xsl; \
  # install PECL Extensions
  echo no | pecl install mcrypt-1.0.1 redis; \
  docker-php-ext-enable mcrypt redis; \
  rm -rf /tmp/pear; \
  # cleanup
  apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false $buildDeps; \
  rm -rf /var/lib/apt/lists/*