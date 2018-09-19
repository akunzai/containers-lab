FROM php:7.0-cli
ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8
RUN set -ex; \
  apt-get update; \
  apt-get install -y --no-install-recommends \
    ca-certificates cron curl git mysql-client openssh-client unzip vim-tiny \
    libfreetype6 libjpeg62-turbo libpng16-16 libicu57 libmcrypt4 libxml2 libxslt1.1; \
  buildDeps="libfreetype6-dev libjpeg62-turbo-dev libpng-dev \
    libmcrypt-dev libicu-dev \
    libxml2-dev libxslt1-dev"; \
  apt-get install -y --no-install-recommends $buildDeps; \
  ## Install PHP Extensions
  docker-php-ext-install -j$(nproc) \
    gd mcrypt mysqli opcache zip \
    intl pcntl pdo_mysql soap xsl; \
  ## Install PECL Extensions
  echo no | pecl install redis; \
  docker-php-ext-enable redis; \
  rm -rf /tmp/pear; \
  ## Install Composer
  curl -fSL -o /tmp/composer-setup.php https://getcomposer.org/installer; \
  curl -fSL -o /tmp/composer-setup.sig https://composer.github.io/installer.sig; \
  php -r "if (hash('SHA384', file_get_contents('/tmp/composer-setup.php')) !== trim(file_get_contents('/tmp/composer-setup.sig'))) { unlink('/tmp/composer-setup.php'); echo 'Invalid installer' . PHP_EOL; exit(1); }"; \
  php /tmp/composer-setup.php --install-dir=/usr/local/bin/ --filename=composer; \
  rm -f /tmp/composer-setup.*; \
  ## Cleanup
  apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false $buildDeps; \
  rm -rf /var/lib/apt/lists/*