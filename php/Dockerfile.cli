FROM php:7.3-cli
ENV LANG=C.UTF-8
RUN set -ex; \
  # ensure www-data userhome & permissions
  mkdir -p /var/www/html; \
  chown -R www-data:www-data /var/www; \
  # persistent / runtime deps
  apt-get update; \
  apt-get install -y --no-install-recommends \
    ca-certificates cron curl git mariadb-client openssh-client procps unzip vim-tiny \
    libfreetype6 libjpeg62-turbo libpng16-16 libicu63 libmcrypt4 libwebp6 libxpm4 libxslt1.1 libzip4; \
  # dependencies required for building
  buildDeps="libfreetype6-dev libjpeg-dev libpng-dev \
    libmcrypt-dev libicu-dev libwebp-dev \
    libxpm-dev libxslt1-dev libzip-dev"; \
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
  echo no | pecl install mcrypt-snapshot redis; \
  docker-php-ext-enable mcrypt redis; \
  rm -rf /tmp/pear; \
  # install PHP Composer
  curl -fSL -o /tmp/composer-setup.php https://getcomposer.org/installer; \
  curl -fSL -o /tmp/composer-setup.sig https://composer.github.io/installer.sig; \
  php -r "if (hash('SHA384', file_get_contents('/tmp/composer-setup.php')) !== trim(file_get_contents('/tmp/composer-setup.sig'))) { unlink('/tmp/composer-setup.php'); echo 'Invalid installer' . PHP_EOL; exit(1); }"; \
  php /tmp/composer-setup.php --install-dir=/usr/local/bin/ --filename=composer; \
  rm -f /tmp/composer-setup.*; \
  # install modman
  curl -fSL -o /usr/local/bin/modman https://raw.githubusercontent.com/colinmollenhour/modman/master/modman; \
  chmod +x /usr/local/bin/modman; \
  # install n98-magerun
  curl -fSL -o /usr/local/bin/n98-magerun.phar https://files.magerun.net/n98-magerun.phar; \
  chmod +x /usr/local/bin/n98-magerun.phar; \
  ln -s /usr/local/bin/n98-magerun.phar /usr/local/bin/n98-magerun; \
  # cleanup
  apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false $buildDeps; \
  rm -rf /var/lib/apt/lists/*