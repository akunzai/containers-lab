# https://github.com/Azure-App-Service/tomcat/blob/dev/8.5-jre8/Dockerfile
FROM mcr.microsoft.com/java/jre-headless:8-zulu-alpine-with-tools

ENV AI_VERSION 2.6.2
ENV TOMCAT_VERSION 8.5.58
ENV TOMCAT_MAJOR 8
ENV APPINSIGHTS_ENABLED 1

ENV PORT 80
ENV SSH_PORT 2222

ENV PATH /usr/local/tomcat/bin:$PATH

# Remove the sample webapps provided by Tomcat
RUN rm -rf /usr/local/tomcat/webapps/

COPY ./init_container.sh /bin/init_container.sh
COPY ./sshd_config /etc/ssh/
COPY ./tomcat/webapps/ROOT/index.jsp /tmp/tomcat/webapps/ROOT/index.jsp
COPY ./app_insights/AI-Agent.xml /usr/local/app_insights/aiagent/
COPY ./app_insights/ApplicationInsights.xml /usr/local/app_insights/tomcat_lib/
COPY ./app_insights/web-appservice-ai.xml /tmp/tomcat/conf/web-appservice-ai.xml

RUN apk add --no-cache openssh-server bash openrc bash \
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
        && echo "root:Docker!" | chpasswd \
        && wget -O /tmp/apache-tomcat-$TOMCAT_VERSION.tar.gz https://archive.apache.org/dist/tomcat/tomcat-$TOMCAT_MAJOR/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz --no-verbose \
        && tar xvzf /tmp/apache-tomcat-$TOMCAT_VERSION.tar.gz -C /tmp \
        && mv /tmp/apache-tomcat-$TOMCAT_VERSION /usr/local/tomcat \
        && rm -rf /usr/local/tomcat/webapps \
        && rm -f /tmp/apache-tomcat-$TOMCAT_VERSION.tar.gz \
        && wget -O /usr/local/app_insights/tomcat_lib/applicationinsights-core-$AI_VERSION.jar https://github.com/Microsoft/ApplicationInsights-Java/releases/download/$AI_VERSION/applicationinsights-core-$AI_VERSION.jar --no-verbose \
        && wget -O /usr/local/app_insights/tomcat_lib/applicationinsights-web-$AI_VERSION.jar https://github.com/Microsoft/ApplicationInsights-Java/releases/download/$AI_VERSION/applicationinsights-web-$AI_VERSION.jar --no-verbose \
        && wget -O /usr/local/app_insights/aiagent/applicationinsights-agent-$AI_VERSION.jar https://github.com/Microsoft/ApplicationInsights-Java/releases/download/$AI_VERSION/applicationinsights-agent-$AI_VERSION.jar --no-verbose \
        && chmod 755 /bin/init_container.sh \
        && find ./bin/ -name '*.sh' -exec sed -ri 's|^#!/bin/sh$|#!/usr/bin/env bash|' '{}' +

COPY ./tomcat/conf/* /usr/local/tomcat/conf/
COPY ./tomcat/lib/*.jar /usr/local/tomcat/lib/
COPY ./tomcat/bin/setenv.sh /usr/local/tomcat/bin/

EXPOSE 80 2222

ENTRYPOINT ["/bin/init_container.sh"]