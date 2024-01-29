FROM debian:buster-slim

ENV DEBIAN_FRONTEND noninteractive

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends tini gosu squid procps; \
    rm -rf /var/lib/apt/lists/*; \
    sed -i -E 's/^#(http_access allow localnet)/\1/' /etc/squid/conf.d/debian.conf;

COPY --chmod=755 startup.sh /

VOLUME /var/spool/squid

EXPOSE 3128

CMD /startup.sh

ENTRYPOINT ["/usr/bin/tini","--"]