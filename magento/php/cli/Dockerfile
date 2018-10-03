FROM php:7.2-cli
ENV LANG=C.UTF-8
RUN set -ex; \
  # ensure www-data userhome & permissions
  mkdir -p /var/www/html; \
  chown -R www-data:www-data /var/www; \
  # persistent / runtime deps
  apt-get update; \
  apt-get install -y --no-install-recommends \
    ca-certificates cron curl git mysql-client openssh-client unzip vim-tiny \
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