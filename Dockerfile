FROM haproxy:1.7-alpine

ARG KEEPALIVED_VERSION=1.3.9

COPY docker-entrypoint.sh /
COPY start.sh /
COPY haproxy/haproxy_cfg_init.sh /haproxy/

RUN apk add wget gcc libc-dev libnl-dev openssl openssl-dev libnfnetlink-dev make linux-headers \
# install keepalived
    && wget -O /tmp/keepalived.tar.gz "http://www.keepalived.org/software/keepalived-${KEEPALIVED_VERSION}.tar.gz" \
    && mkdir -p /tmp/keepalived && tar -xf /tmp/keepalived.tar.gz -C /tmp/keepalived --strip-components 1 \
    && cd /tmp/keepalived && ./configure && make && make install

# override haproxy's entrypoint
ENTRYPOINT []

CMD ["/start.sh"]
