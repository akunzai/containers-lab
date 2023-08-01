ARG PHP_VERSION=8.1
# https://hub.docker.com/_/php
FROM php:$PHP_VERSION-apache-bookworm

ARG APT_URL=""
ENV LANG=C.UTF-8

RUN set -eux; \
    # preferred mirror site
    [ -n "$APT_URL" ] && [ "$APT_URL" = 'http://free.nchc.org.tw' ] && [ $(uname -m) = 'x86_64' ] && [ -e "/etc/apt/sources.list.d/debian.sources" ] && sed -i -E "/-security/! s,URIs: http?://[^\/]+,URIs: $APT_URL,g" /etc/apt/sources.list.d/debian.sources; \
    [ -n "$APT_URL" ] && [ "$APT_URL" != 'http://free.nchc.org.tw' ] && [ -e "/etc/apt/sources.list.d/debian.sources" ] && sed -i -E "s,URIs: http?://[^\/]+,URIs: $APT_URL,g" /etc/apt/sources.list.d/debian.sources; \
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
    libpng-dev libxml2-dev libxslt1-dev libzip-dev libwebp-dev \
    ${PHP_EXTRA_BUILD_DEPS:-}; \
    # https://www.php.net/manual/en/image.installation.php
    docker-php-ext-configure gd --enable-gd --with-freetype --with-jpeg --with-webp; \
    docker-php-ext-install -j$(nproc) opcache \
    intl gd mysqli pcntl pdo_mysql soap xsl zip; \
    # reset apt-mark's "manual" list so that "purge --auto-remove" will remove all build dependencies
    apt-mark auto '.*' > /dev/null; \
    [ -z "$savedAptMark" ] || apt-mark manual $savedAptMark; \
    find /usr/local -type f -executable -exec ldd '{}' ';' \
    | awk '/=>/ { so = $(NF-1); if (index(so, "/usr/local/") == 1) { next }; gsub("^/(usr/)?", "", so); print so }' \
    | sort -u \
    | xargs -r dpkg-query --search \
    | cut -d: -f1 \
    | sort -u \
    | xargs -r apt-mark manual; \
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
    rm -rf /var/lib/apt/lists/*;
RUN set -eux; \
    # https://github.com/FriendsOfPHP/pickle
    curl -Lo /usr/local/bin/pickle https://github.com/FriendsOfPHP/pickle/releases/latest/download/pickle.phar && \
    chmod +x /usr/local/bin/pickle; \
    pickle install --no-interaction apcu; \
    pickle install --no-interaction redis; \
    pickle install --no-interaction xdebug; \
    docker-php-ext-enable apcu redis xdebug;

# https://hub.docker.com/_/composer
COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer