# https://github.com/Azure-App-Service/java/blob/dev/jre8-alpine/Dockerfile
# https://github.com/microsoft/java/tree/master/docker/alpine/Dockerfile.zulu-8u265-jre-headless-tools
FROM mcr.microsoft.com/java/jre-headless:8-zulu-alpine-with-tools

ENV PORT 80
ENV SSH_PORT 2222

COPY ./appservice/* /tmp/appservice/
COPY ./init_container.sh /bin/init_container.sh
COPY ./sshd_config /etc/ssh/

#
# Enable and conigure SSH:
#
RUN apk add --no-cache openssh-server openrc bash\
        && echo "root:Docker!" | chpasswd \
        && rm -rf /var/cache/apk/* \
        # Remove unnecessary services
        && rm -f /etc/init.d/hwdrivers \
                 /etc/init.d/hwclock \
                 /etc/init.d/mtab \
                 /etc/init.d/bootmisc \
                 /etc/init.d/modules \
                 /etc/init.d/modules-load \
                 /etc/init.d/modloop \
        # Can't do cgroups
        && sed -i 's/\tcgroup_add_service/\t#cgroup_add_service/g' /lib/rc/sh/openrc-run.sh \
        && chmod 755 /bin/init_container.sh \
        && find ./bin/ -name '*.sh' -exec sed -ri 's|^#!/bin/sh$|#!/usr/bin/env bash|' '{}' +

EXPOSE 80 2222

ENTRYPOINT ["/bin/init_container.sh"]