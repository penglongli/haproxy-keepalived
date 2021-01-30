# Build the manager binary
FROM golang:1.14 as builder

WORKDIR /workspace/src/github.com/penglongli/haproxy-keepalived

ENV GOPATH /workspace

COPY go.mod go.mod
COPY vendor vendor
COPY go.sum go.sum
COPY main.go main.go
COPY server server
COPY version version

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 GO111MODULE=on go build -mod vendor -v -x  -o haproxy-keepalived main.go

# Build
FROM alpine:3.12

COPY conf/locale.md /
COPY conf/rsyslog.conf /etc/rsyslog.d/

ENV HAPROXY_VERSION 2.3.4
ENV HAPROXY_URL https://www.haproxy.org/download/2.3/src/haproxy-2.3.4.tar.gz
ENV HAPROXY_SHA256 60148cdfedd6b19c401dbcd75ccd76a53c20bc76c49032ba32af98a0a5c495ed
ENV KEEPALIVED_VERSION 1.3.9
ENV KEEPALIVED_URL http://www.keepalived.org/software/keepalived-1.3.9.tar.gz

# see https://sources.debian.net/src/haproxy/jessie/debian/rules/ for some helpful navigation of the possible "make" arguments
RUN set -x \
	\
	&& apk add --no-cache --virtual .build-deps \
		gcc \
		libc-dev \
		linux-headers \
		lua5.3-dev \
		make \
		openssl \
		openssl-dev \
		pcre2-dev \
		readline-dev \
		tar \
		zlib-dev \
	\
# install HAProxy
	&& wget -O haproxy.tar.gz "$HAPROXY_URL" \
	&& echo "$HAPROXY_SHA256 *haproxy.tar.gz" | sha256sum -c \
	&& mkdir -p /usr/src/haproxy \
	&& tar -xzf haproxy.tar.gz -C /usr/src/haproxy --strip-components=1 \
	&& rm haproxy.tar.gz \
	\
	&& makeOpts=' \
		TARGET=linux-musl \
		USE_GETADDRINFO=1 \
		USE_LUA=1 LUA_INC=/usr/include/lua5.3 LUA_LIB=/usr/lib/lua5.3 \
		USE_OPENSSL=1 \
		USE_PCRE2=1 USE_PCRE2_JIT=1 \
		USE_ZLIB=1 \
		\
		EXTRA_OBJS=" \
# see https://github.com/docker-library/haproxy/issues/94#issuecomment-505673353 for more details about prometheus support
			contrib/prometheus-exporter/service-prometheus.o \
		" \
	' \
	&& nproc="$(getconf _NPROCESSORS_ONLN)" \
	&& eval "make -C /usr/src/haproxy -j '$nproc' all $makeOpts" \
	&& eval "make -C /usr/src/haproxy install-bin $makeOpts" \
	\
	&& mkdir -p /usr/local/etc/haproxy \
	&& cp -R /usr/src/haproxy/examples/errorfiles /usr/local/etc/haproxy/errors \
	&& rm -rf /usr/src/haproxy \
# install Keepalived
    && wget -O keepalived.tar.gz "${KEEPALIVED_URL}" \
    && mkdir -p /usr/src/keepalived \
    && tar -xzf keepalived.tar.gz -C /usr/src/keepalived --strip-components=1 \
    && rm keepalived.tar.gz \
    && cd /usr/src/keepalived \
    && ./configure \
    && make && make install \
    && apk --no-cache add ca-certificates \
# add locale: https://github.com/gliderlabs/docker-alpine/issues/144#issuecomment-339906345
    && wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub \
    && wget -q -P /tmp https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.28-r0/glibc-2.28-r0.apk \
    && wget -q -P /tmp https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.28-r0/glibc-bin-2.28-r0.apk \
    && wget -q -P /tmp https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.28-r0/glibc-i18n-2.28-r0.apk \
    && apk add /tmp/glibc-2.28-r0.apk /tmp/glibc-bin-2.28-r0.apk /tmp/glibc-i18n-2.28-r0.apk \
    && cat /locale.md | xargs -i /usr/glibc-compat/bin/localedef -i {} -f UTF-8 {}.UTF-8 \
# rsyslog, refer to: https://github.com/mminks/haproxy-docker-logging/blob/master/Dockerfile
    && apk add rsyslog \
    && mkdir -p /etc/rsyslog.d && touch /var/log/haproxy.log \
    && rm -rf /tmp/* \
    \
	&& runDeps="$( \
		scanelf --needed --nobanner --format '%n#p' --recursive /usr/local \
			| tr ',' '\n' \
			| sort -u \
			| awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
	)" \
	&& apk add --no-network --virtual .haproxy-rundeps $runDeps \
	&& apk del --no-network .build-deps

ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8

WORKDIR /
COPY --from=builder /workspace/src/github.com/penglongli/haproxy-keepalived/haproxy-keepalived .

ENTRYPOINT ["/haproxy-keepalived"]
