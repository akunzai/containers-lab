# https://github.com/docker-library/docs/tree/master/centos#systemd-integration
ARG CENTOS_VERSION=8
FROM centos:$CENTOS_VERSION

ENV container docker

RUN cd /lib/systemd/system/sysinit.target.wants/; \
    for i in *; do [ $i == systemd-tmpfiles-setup.service ] || rm -f $i; done; \
    rm -f /lib/systemd/system/multi-user.target.wants/* \
    /etc/systemd/system/*.wants/* \
    /lib/systemd/system/local-fs.target.wants/* \
    /lib/systemd/system/sockets.target.wants/*udev* \
    /lib/systemd/system/sockets.target.wants/*initctl* \
    /lib/systemd/system/basic.target.wants/* \
    /lib/systemd/system/anaconda.target.wants/*

VOLUME [ "/sys/fs/cgroup" ]

CMD ["/usr/sbin/init"]

# https://systemd.io/CONTAINER_INTERFACE/#advanced-integration
STOPSIGNAL SIGRTMIN+3