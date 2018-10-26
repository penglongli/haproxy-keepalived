FROM haproxy:1.7-alpine

LABEL maintainer="Peling <penglong95.li@gmail.com>"

ARG KEEPALIVED_VERSION=1.3.9

COPY start.sh /
COPY script/locale.md /
COPY script/chk_haproxy.sh /usr/local/bin/ 

RUN apk add wget gcc libc-dev libnl-dev openssl openssl-dev libnfnetlink-dev make linux-headers rsyslog \
# install keepalived
    && wget -O /tmp/keepalived.tar.gz "http://www.keepalived.org/software/keepalived-${KEEPALIVED_VERSION}.tar.gz" \
    && mkdir -p /tmp/keepalived && tar -xf /tmp/keepalived.tar.gz -C /tmp/keepalived --strip-components 1 \
    && cd /tmp/keepalived && ./configure && make && make install \
# add locale: https://github.com/gliderlabs/docker-alpine/issues/144#issuecomment-339906345
    && apk --no-cache add ca-certificates wget \
    && wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub \
    && wget -q -P /tmp https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.28-r0/glibc-2.28-r0.apk \
    && wget -q -P /tmp https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.28-r0/glibc-bin-2.28-r0.apk \
    && wget -q -P /tmp https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.28-r0/glibc-i18n-2.28-r0.apk \
    && apk add /tmp/glibc-2.28-r0.apk /tmp/glibc-bin-2.28-r0.apk /tmp/glibc-i18n-2.28-r0.apk \
    && cat /locale.md | xargs -i /usr/glibc-compat/bin/localedef -i {} -f UTF-8 {}.UTF-8 \
# rsyslog, refer to: https://github.com/mminks/haproxy-docker-logging/blob/master/Dockerfile
    && mkdir -p /etc/rsyslog.d && touch /var/log/haproxy.log \
    && cd /tmp && rm -rf /tmp/*

COPY script/rsyslog.conf /etc/rsyslog.d/

# override haproxy's SIGUSR1 
STOPSIGNAL SIGTERM 

ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8

# override haproxy's entrypoint
ENTRYPOINT []

CMD ["/start.sh"]
