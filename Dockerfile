FROM haproxy:1.7.9

RUN apt-get update -y && apt-get upgrade -y
RUN apt-get install -y gettext

# install keepalived
RUN mkdir -p /data/keepalived && cd /data && apt-get install -y wget \
    && wget http://www.keepalived.org/software/keepalived-1.3.9.tar.gz && tar xf keepalived-1.3.9.tar.gz -C keepalived --strip-components 1 \
    && cd keepalived && apt-get install -y gcc && apt-get install -y libssl-dev && apt-get -y install libpopt-dev \
    && ./configure && apt-get install -y make && make && make install

# entrypoint
COPY docker-entrypoint-override.sh /
RUN chmod +x /docker-entrypoint-override.sh

# haproxy
COPY haproxy/haproxy_cfg_init.sh /haproxy/
COPY haproxy/template.cfg /haproxy/

RUN chmod +x /haproxy/haproxy_cfg_init.sh

# keepalived
COPY keepalived/keepalived_template.conf /keepalived/
COPY keepalived/init_keepalived_conf.sh /keepalived/
COPY keepalived/start_keepalived.sh /

RUN chmod +x /keepalived/init_keepalived_conf.sh

# Override haproxy's entrypoint
ENTRYPOINT ["/docker-entrypoint-override.sh"]

# CMD
CMD ["haproxy", "-f", "/usr/local/etc/haproxy/haproxy.cfg"]
