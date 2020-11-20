FROM php:7.4-fpm

RUN set -eux; \
  # persistent / runtime deps
  apt-get update; \
  apt-get install -y --no-install-recommends \
    curl dnsutils nginx openssh-server procps unzip vim-tiny; \
  rm -rf /var/lib/apt/lists/*; \
  # ssh
  echo "root:Docker!" | chpasswd; \
  { echo 'Port 2222'; \
    echo 'ListenAddress 0.0.0.0'; \
    echo 'LoginGraceTime 180'; \
    echo 'X11Forwarding yes'; \
    echo 'Ciphers aes128-cbc,3des-cbc,aes256-cbc,aes128-ctr,aes192-ctr,aes256-ctr'; \
    echo 'MACs hmac-sha1,hmac-sha1-96'; \
    echo 'StrictModes yes'; \
    echo 'SyslogFacility DAEMON'; \
    echo 'PasswordAuthentication yes'; \
    echo 'PermitEmptyPasswords no'; \
    echo 'PermitRootLogin yes'; \
    echo 'Subsystem sftp internal-sftp'; \
  } > /etc/ssh/sshd_config; \
  [ -d "/var/run/sshd" ] || mkdir -p /var/run/sshd; \
  # nginx
  [ -d /home/site/wwwroot ] || mkdir -p /home/site/wwwroot; \
  rm -rf /var/www/html; \
  ln -s /home/site/wwwroot /var/www/html; \
  ln -sfT /dev/stdout /var/log/nginx/access.log; \
  ln -sfT /dev/stderr /var/log/nginx/error.log; \
  sed -ri -e 's!worker_connections 768!worker_connections 10068!g' /etc/nginx/nginx.conf; \
  sed -ri -e 's!# multi_accept on!multi_accept on!g' /etc/nginx/nginx.conf; \
  echo "<?php phpinfo();" > /home/site/wwwroot/index.php; \
  # php-fpm
  { echo 'opcache.max_accelerated_files=4000'; \
    echo 'opcache.revalidate_freq=60'; \
    echo 'opcache.enable_cli=1'; \
  } > /usr/local/etc/php/conf.d/opcache-recommended.ini; \
  { echo 'error_log=/dev/stderr'; \
    echo 'log_errors=On'; \
    echo 'display_errors=Off'; \
    echo 'display_startup_errors=Off'; \
    echo 'date.timezone=UTC'; \
  } > /usr/local/etc/php/conf.d/php.ini; \
  { echo '[www]'; \
    echo 'listen = /var/run/php/php-fpm.sock'; \
    echo 'listen.owner = www-data'; \
    echo 'listen.group = www-data'; \
    echo 'listen.mode = 0660'; \
    echo 'pm = ondemand'; \
    echo 'pm.max_children = 20'; \
  } > /usr/local/etc/php-fpm.d/zz-docker.conf; \
  [ -d "/var/run/php" ] || mkdir -p /var/run/php; \
  # Azure App Service
  mkdir -p /home/LogFiles/;

COPY nginx.conf /etc/nginx/sites-available/default

# PHP extensions
RUN set -eux; \
  savedAptMark="$(apt-mark showmanual)"; \
  apt-get update; \
  apt-get install -y --no-install-recommends \
    libfreetype6-dev libicu-dev libjpeg62-turbo-dev libpng-dev libxslt1-dev libzip-dev libwebp-dev\
    ${PHP_EXTRA_BUILD_DEPS:-}; \
  rm -rf /var/lib/apt/lists/*; \
  # https://www.php.net/manual/en/image.installation.php
  docker-php-ext-configure gd --enable-gd --with-freetype --with-jpeg --with-webp; \
  docker-php-ext-install -j$(nproc) \
    intl gd mysqli opcache pcntl pdo_mysql xmlrpc xsl zip; \
  # reset apt-mark's "manual" list so that "purge --auto-remove" will remove all build dependencies
  apt-mark auto '.*' > /dev/null; \
  [ -z "$savedAptMark" ] || apt-mark manual $savedAptMark; \
  find /usr/local -type f -executable -exec ldd '{}' ';' \
    | awk '/=>/ { print $(NF-1) }' \
    | sort -u \
    | xargs -r dpkg-query --search \
    | cut -d: -f1 \
    | sort -u \
    | xargs -r apt-mark manual; \
  apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
  # update pecl channel definitions https://github.com/docker-library/php/issues/443
  pecl update-channels; \
  rm -rf /tmp/pear ~/.pearrc; \
  # smoke test
  php -m;

ENV TINI_VERSION v0.19.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini;
ENTRYPOINT ["/tini", "--"]

STOPSIGNAL SIGTERM

EXPOSE 2222 8080

CMD /usr/sbin/sshd; /usr/local/sbin/php-fpm -D; nginx -g "daemon off;"