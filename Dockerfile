FROM haproxy:1.7-alpine

ARG KEEPALIVED_VERSION=1.3.9

COPY start.sh /

RUN apk add wget gcc libc-dev libnl-dev openssl openssl-dev libnfnetlink-dev make linux-headers \
# install keepalived
    && wget -O /tmp/keepalived.tar.gz "http://www.keepalived.org/software/keepalived-${KEEPALIVED_VERSION}.tar.gz" \
    && mkdir -p /tmp/keepalived && tar -xf /tmp/keepalived.tar.gz -C /tmp/keepalived --strip-components 1 \
    && cd /tmp/keepalived && ./configure && make && make install \
    && cd /tmp && rm -rf /tmp/*

# override haproxy's entrypoint
ENTRYPOINT []

CMD ["/start.sh"]
