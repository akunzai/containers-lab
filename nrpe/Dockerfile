FROM docker.io/library/debian:bookworm-slim

ENV DEBIAN_FRONTEND noninteractive

RUN --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    --mount=type=cache,target=/var/cache/apt,sharing=locked \
    set -eux; \
    apt-get update && apt-get upgrade -y; \
    apt-get install -y --no-install-recommends procps net-tools \
        nagios-nrpe-server nagios-nrpe-plugin monitoring-plugins-basic; \
    sed -i -E 's|^#(log_file=/var/log/nrpe.log)|\1|' /etc/nagios/nrpe.cfg; \
    # ensure log directory exists and fixes permission
	touch /var/log/nrpe.log; \
	chown nagios:nagios /var/log/nrpe.log; \
    # ensure pid directory exists and fixes permission
    mkdir -p /var/run/nagios; \
    chown -R nagios:nagios /var/run/nagios;

COPY --chmod=755 check_mem.sh /usr/lib/nagios/plugins/
COPY --chmod=755 entrypoint.sh /

EXPOSE 5666
ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/sbin/nrpe","-c","/etc/nagios/nrpe.cfg","-d"]