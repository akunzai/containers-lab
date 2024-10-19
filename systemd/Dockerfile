# https://github.com/j8r/dockerfiles/tree/master/systemd/debian
ARG DEBIAN_VERSION=11
FROM docker.io/library/debian:$DEBIAN_VERSION

ENV container docker
ENV DEBIAN_FRONTEND noninteractive

RUN --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    --mount=type=cache,target=/var/cache/apt,sharing=locked \
    apt-get update; \
    apt-get install -y --no-install-recommends \
    systemd systemd-sysv; \
    apt-get clean; \
    rm -rf /tmp/* /var/tmp/*; \
    rm -f /lib/systemd/system/multi-user.target.wants/* \
    /etc/systemd/system/*.wants/* \
    /lib/systemd/system/local-fs.target.wants/* \
    /lib/systemd/system/sockets.target.wants/*udev* \
    /lib/systemd/system/sockets.target.wants/*initctl* \
    /lib/systemd/system/sysinit.target.wants/systemd-tmpfiles-setup* \
    /lib/systemd/system/systemd-update-utmp*

VOLUME [ "/sys/fs/cgroup" ]

CMD ["/lib/systemd/systemd"]

# https://systemd.io/CONTAINER_INTERFACE/#advanced-integration
STOPSIGNAL SIGRTMIN+3