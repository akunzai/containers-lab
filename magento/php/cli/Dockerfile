FROM php:7.0-cli
RUN set -ex; \
  apt-get update; \
  apt-get install -y --no-install-recommends \
    ca-certificates cron curl git mysql-client openssh-client unzip vim-tiny \
    libfreetype6 libjpeg62-turbo libpng12-0 \
    libicu52 libmcrypt4 \
    libxml2 libxslt1.1; \
  buildDeps="libfreetype6-dev libjpeg62-turbo-dev libpng12-dev \
    libmcrypt-dev libicu-dev \
    libxml2-dev libxslt1-dev"; \
  apt-get install -y --no-install-recommends $buildDeps; \
  # Install gosu
  GOSU_VERSION="1.10"; \
  dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')"; \
  curl -fSL -o /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch"; \
  curl -fSL -o /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc"; \
  export GNUPGHOME="$(mktemp -d)"; \
  gpg --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4; \
  gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu; \
  rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc; \
  chmod +x /usr/local/bin/gosu; \
  # Install PHP Extensions
  docker-php-ext-install -j$(nproc) \
    gd mcrypt mysqli opcache zip \
    intl pcntl pdo_mysql soap xsl; \
  # Install PECL Extensions
  echo no | pecl install redis; \
  docker-php-ext-enable redis; \
  rm -rf /tmp/pear; \
  # Install Composer
  curl -fSL -o /tmp/composer-setup.php https://getcomposer.org/installer; \
  curl -fSL -o /tmp/composer-setup.sig https://composer.github.io/installer.sig; \
  php -r "if (hash('SHA384', file_get_contents('/tmp/composer-setup.php')) !== trim(file_get_contents('/tmp/composer-setup.sig'))) { unlink('/tmp/composer-setup.php'); echo 'Invalid installer' . PHP_EOL; exit(1); }"; \
  php /tmp/composer-setup.php --install-dir=/usr/local/bin/ --filename=composer; \
  rm -f /tmp/composer-setup.*; \
  # Install modman
  curl -fSL -o /usr/local/bin/modman https://raw.githubusercontent.com/colinmollenhour/modman/master/modman; \
  chmod +x /usr/local/bin/modman; \
  # Install n98-magerun
  curl -fSL -o /usr/local/bin/n98-magerun.phar https://files.magerun.net/n98-magerun.phar; \
  chmod +x /usr/local/bin/n98-magerun.phar; \
  ln -s /usr/local/bin/n98-magerun.phar /usr/local/bin/n98-magerun; \
  # Cleanup
  apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false $buildDeps; \
  rm -rf /var/lib/apt/lists/*