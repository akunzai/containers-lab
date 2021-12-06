ARG PHP_VERSION=8.0
# https://hub.docker.com/_/php
FROM php:$PHP_VERSION-apache

ARG APT_URL=""
ENV LANG=C.UTF-8

RUN set -eux; \
    # preferred mirror site
    [ -n "${APT_URL}" ] && sed -i "s,^\deb http://deb.debian.org,deb ${APT_URL},g" /etc/apt/sources.list; \
    # enable Apache2 modules
    a2enmod rewrite expires include deflate remoteip headers; \
    # disable Apache2 server signature
    echo 'ServerSignature Off' >> /etc/apache2/apache2.conf; \
    echo 'ServerTokens Prod' >> /etc/apache2/apache2.conf; \
    # install common PHP extensions
    savedAptMark="$(apt-mark showmanual)"; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
    libfreetype6-dev libicu-dev libjpeg62-turbo-dev \
    libpng-dev libxslt1-dev libzip-dev libwebp-dev \
    ${PHP_EXTRA_BUILD_DEPS:-}; \
    rm -rf /var/lib/apt/lists/*; \
    # https://www.php.net/manual/en/image.installation.php
    docker-php-ext-configure gd --enable-gd --with-freetype --with-jpeg --with-webp; \
    docker-php-ext-install -j$(nproc) opcache \
    intl gd mysqli pcntl pdo_mysql xsl zip; \
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
    php -m && php -v && apache2 -v;