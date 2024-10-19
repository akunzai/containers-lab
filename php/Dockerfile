ARG PHP_VERSION=8.2
# https://hub.docker.com/_/php
FROM docker.io/library/php:${PHP_VERSION}-apache-bookworm

ARG APT_URL=""
ENV LANG=C.UTF-8

# preferred mirror site
RUN ([ -n "$APT_URL" ] && \
    [ "$APT_URL" = 'http://free.nchc.org.tw' ] && [ "$(uname -m)" = 'x86_64' ] && \
    [ -e "/etc/apt/sources.list.d/debian.sources" ] && \
    sed -i -E "/-security/! s,URIs: http?://[^\/]+,URIs: $APT_URL,g" /etc/apt/sources.list.d/debian.sources) || true; \
    ([ -n "$APT_URL" ] && [ "$APT_URL" != 'http://free.nchc.org.tw' ] && \
    [ -e "/etc/apt/sources.list.d/debian.sources" ] && \
    sed -i -E "s,URIs: http?://[^\/]+,URIs: $APT_URL,g" /etc/apt/sources.list.d/debian.sources) || true;

# install pickle
# https://github.com/FriendsOfPHP/pickle
RUN set -eux; \
    curl -Lo /usr/local/bin/pickle https://github.com/FriendsOfPHP/pickle/releases/latest/download/pickle.phar && \
    chmod +x /usr/local/bin/pickle;

# install the PHP extensions we need
# hadolint ignore=SC2086
RUN set -eux; \
    savedAptMark="$(apt-mark showmanual)"; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
    libfreetype6-dev libicu-dev libjpeg62-turbo-dev \
    libpng-dev libxml2-dev libxslt1-dev libzip-dev libwebp-dev \
    "${PHP_EXTRA_BUILD_DEPS:-}"; \
    # https://www.php.net/manual/en/image.installation.php
    docker-php-ext-configure gd --enable-gd --with-freetype --with-jpeg --with-webp; \
    docker-php-ext-install -j$(nproc) opcache \
    intl gd mysqli pcntl pdo_mysql soap xsl zip; \
    pickle install --no-interaction apcu-stable; \
    pickle install --no-interaction redis-stable; \
    pickle install --no-interaction xdebug-stable; \
    docker-php-ext-enable apcu opcache redis xdebug; \
    # reset apt-mark's "manual" list so that "purge --auto-remove" will remove all build dependencies
    apt-mark auto '.*' > /dev/null; \
    [ -z "${savedAptMark}" ] || apt-mark manual $savedAptMark; \
    find /usr/local -type f -executable -exec ldd '{}' ';' \
    | awk '/=>/ { so = $(NF-1); if (index(so, "/usr/local/") == 1) { next }; gsub("^/(usr/)?", "", so); print so }' \
    | sort -u \
    | xargs -r dpkg-query --search \
    | cut -d: -f1 \
    | sort -u \
    | xargs -r apt-mark manual; \
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
    rm -rf /var/lib/apt/lists/* /tmp/*;

# set up Apache2
RUN set -eux; \
    # change listening port from 80 to 8080
    sed -i 's/Listen 80/Listen 8080/' /etc/apache2/ports.conf; \
    sed -i 's/*:80/*:8080/' /etc/apache2/sites-available/000-default.conf; \
    # change listening port from 443 to 8443
    sed -i 's/Listen 443/Listen 8443/' /etc/apache2/ports.conf; \
    # enable Apache2 modules
    a2enmod rewrite expires include deflate remoteip headers ssl socache_shmcb; \
    { \
        # disable Apache2 server signature
        echo 'ServerSignature Off'; \
        echo 'ServerTokens Prod'; \
        # enable support for TLS termination
        echo 'SetEnvIf X-Forwarded-Proto https HTTPS=on';  \
    } >> /etc/apache2/apache2.conf;

# install composer
# https://hub.docker.com/_/composer
COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer