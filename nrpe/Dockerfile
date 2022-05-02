FROM debian:buster-slim

ENV DEBIAN_FRONTEND noninteractive

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends tini gosu procps net-tools \
        nagios-nrpe-server nagios-nrpe-plugin monitoring-plugins-basic; \
    rm -rf /var/lib/apt/lists/*; \
    sed -i -E 's|^#(log_file=/var/log/nrpe.log)|\1|' /etc/nagios/nrpe.cfg;

COPY check_mem.sh /usr/lib/nagios/plugins/
COPY startup.sh /

RUN chmod 755 /startup.sh /usr/lib/nagios/plugins/check_mem.sh

EXPOSE 5666

CMD /startup.sh

ENTRYPOINT ["/usr/bin/tini","--"]