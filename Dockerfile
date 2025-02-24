ARG BASE_VERSION=3.21.2
ARG BASE_HASH=56fa17d2a7e7f168a043a2712e63aed1f8543aeafdcee47c58dcffe38ed51099
FROM docker.io/library/alpine:${BASE_VERSION}@sha256:${BASE_HASH} AS builder
ARG OPENSSL_VERSION=openssl-3.4.1
ARG APP_VERSION=release-1.27.4
ARG NJS_VERSION=0.8.9

RUN NB_CORES="${BUILD_CORES-$(getconf _NPROCESSORS_CONF)}" \
&& set -ex && addgroup --gid 101 -S freenginx && adduser -S freenginx --uid 101 -s /sbin/nologin -G freenginx --no-create-home \
&& apk -U upgrade && apk add --no-cache \
    openssl \
    pcre \
    libgcc \
    libstdc++ \
    g++ \
    make \
    build-base \
    linux-headers \
    ca-certificates \
    automake \
    autoconf \
    git \
    talloc \
    talloc-dev \
    libtool \
    pcre-dev \
    binutils \
    gnupg \
    cmake \
    go \
    libxslt \
    libxslt-dev \
    tini \
    musl-dev \
    ncurses-libs \
    gd-dev \
    brotli-libs \
    ca-certificates \
&& update-ca-certificates && cd /tmp \
&& git clone --depth 1 --recursive --single-branch -b "${APP_VERSION}" https://github.com/freenginx/nginx && rm -rf /tmp/nginx/docs/html/* \
&& sed -i -e 's@"nginx/"@" "@g' /tmp/nginx/src/core/nginx.h \
&& sed -i -e 's@"nginx version: "@" "@g' /tmp/nginx/src/core/nginx.c \
&& sed -i -e 's@"freenginx"@" "@g' /tmp/nginx/src/core/nginx.h \
&& sed -i -e 's@"freenginx version: "@" "@g' /tmp/nginx/src/core/nginx.c \
&& sed -i -e 's@r->headers_out.server == NULL@0@g' /tmp/nginx/src/http/ngx_http_header_filter_module.c \
&& sed -i -e 's@r->headers_out.server == NULL@0@g' /tmp/nginx/src/http/v2/ngx_http_v2_filter_module.c \
&& sed -i -e 's@r->headers_out.server == NULL@0@g' /tmp/nginx/src/http/v3/ngx_http_v3_filter_module.c \
&& sed -i -e 's@<hr><center>freenginx</center>@@g' /tmp/nginx/src/http/ngx_http_special_response.c \
&& sed -i -e 's@NGINX_VERSION      ".*"@NGINX_VERSION      " "@g' /tmp/nginx/src/core/nginx.h \
&& sed -i -e 's/SSL_OP_CIPHER_SERVER_PREFERENCE);/SSL_OP_CIPHER_SERVER_PREFERENCE | SSL_OP_PRIORITIZE_CHACHA);/g' /tmp/nginx/src/event/ngx_event_openssl.c \
&& git clone --depth 1 --recursive --single-branch -b ${OPENSSL_VERSION} https://github.com/openssl/openssl \
&& git clone --depth 1 --recursive --shallow-submodules https://github.com/google/ngx_brotli \
&& git clone --depth 1 --recursive --shallow-submodules --single-branch -b ${NJS_VERSION} https://github.com/nginx/njs \
&& cd /tmp/njs && ./configure && make -j "${NB_CORES}" && make clean \
&& mkdir /var/cache/freenginx && cd /tmp/nginx && ./auto/configure \
    --prefix=/etc/freenginx \
    --sbin-path=/usr/sbin/freenginx \
    --user=freenginx \
    --group=freenginx \
    --http-log-path=/tmp/access.log \
    --error-log-path=/tmp/error.log \
    --conf-path=/etc/freenginx/freenginx.conf \
    --pid-path=/tmp/freenginx.pid \
    --lock-path=/tmp/freenginx.lock \
    --http-client-body-temp-path=/var/cache/freenginx/client_temp \
    --http-proxy-temp-path=/var/cache/freenginx/proxy_temp \
    --http-fastcgi-temp-path=/var/cache/freenginx/fastcgi_temp \
    --with-openssl="/tmp/openssl" \
    --with-openssl-opt=enable-ec_nistp_64_gcc_128 \
    --with-cc-opt="-O2" \
    --with-cc-opt="-m64" \
    --with-cc-opt="-march=native" \
    --with-cc-opt="-falign-functions=32" \
    --with-cc-opt="-flto" \
    --with-cc-opt="-fstack-protector-strong" \
    --with-cc-opt="--param=ssp-buffer-size=4" \
    --with-cc-opt="-Wimplicit-fallthrough=0" \
    --with-cc-opt="-Wformat" \
    --with-cc-opt="-Wformat-security" \
    --with-cc-opt="-Werror=format-security" \
    --with-cc-opt="-fcode-hoisting" \
    --with-cc-opt="-Wno-deprecated-declarations" \
    --with-cc-opt="-Wp,-D_FORTIFY_SOURCE=2" \
    --with-cc-opt="-DTCP_FASTOPEN=23" \
    --with-cc-opt="-fPIE" \
    --with-cc-opt="-fno-semantic-interposition" \
    --with-cc-opt="-fno-plt" \
    --with-cc-opt="-std=c11" \
    --with-cc-opt="-fstack-clash-protection" \
    --with-cc-opt="-fdata-sections" \
    --with-cc-opt="-ffunction-sections" \
    --with-ld-opt="-s" \
    --with-ld-opt="-static" \
    --with-ld-opt="-lrt" \
    --with-ld-opt="-ltalloc" \
    --with-ld-opt="-lpcre" \
    --with-ld-opt="-Wl,-z,relro" \
    --with-ld-opt="-Wl,-z,now" \
    --with-ld-opt="-pie" \
    --with-ld-opt="-Wl,--gc-sections" \
    --with-file-aio \
    --with-compat \
    --with-pcre-jit \
    --with-threads \
    --with-http_realip_module \
    --with-http_stub_status_module \
    --with-http_ssl_module \
    --with-http_v2_module \
    --with-http_v3_module \
    --with-http_gzip_static_module \
    --with-stream \
    --with-stream_realip_module \
    --with-stream_ssl_module \
    --with-stream_ssl_preread_module \
    --without-stream_split_clients_module \
    --without-stream_set_module \
    --without-http_geo_module \
    --without-http_scgi_module \
    --without-http_uwsgi_module \
    --without-http_autoindex_module \
    --without-http_split_clients_module \
    --without-http_memcached_module \
    --without-http_ssi_module \
    --without-http_empty_gif_module \
    --without-http_browser_module \
    --without-http_userid_module \
    --without-http_mirror_module \
    --without-http_referer_module \
    --without-mail_pop3_module \
    --without-mail_imap_module \
    --without-mail_smtp_module \
    --add-module=/tmp/njs/nginx \
    --add-module=/tmp/ngx_brotli \
&& make -j "${NB_CORES}" && make install && make clean && strip /usr/sbin/freenginx \
&& chown -R freenginx:freenginx /var/cache/freenginx && chmod -R g+w /var/cache/freenginx \
&& chown -R freenginx:freenginx /etc/freenginx && chmod -R g+w /etc/freenginx && touch /tmp/error.log

FROM scratch
COPY --from=builder /etc/passwd /etc/passwd
COPY --from=builder /etc/group /etc/group
COPY --from=builder /sbin/tini /sbin/tini
COPY --from=builder --chown=freenginx:freenginx /usr/sbin/freenginx /usr/sbin/freenginx
COPY --from=builder --chown=freenginx:freenginx /etc/freenginx /etc/freenginx
COPY --from=builder --chown=freenginx:freenginx /tmp/error.log /tmp/error.log
COPY --from=builder --chown=freenginx:freenginx /var/cache/freenginx /var/cache/freenginx
COPY --chown=freenginx:freenginx ./freenginx.conf /etc/freenginx/freenginx.conf
COPY --chown=freenginx:freenginx ./default.conf /etc/freenginx/conf.d/default.conf
COPY --from=builder /lib/ld-musl-x86_64.so.1 /lib/
COPY --from=builder /usr/lib/libbrotlienc.so.1 \
                    /usr/lib/libpcre.so.1 \
                    /usr/lib/libz.so.1 \
                    /usr/lib/libxml2.so.2 \
                    /usr/lib/libbrotlicommon.so.1 \
                    /usr/lib/liblzma.so.5 /usr/lib/

ENTRYPOINT [ "/sbin/tini", "--" ]

EXPOSE 8080/tcp 8443/tcp 8443/udp
LABEL description="Distroless FreeNGINX built with QUIC and HTTP/3 support🚀" \
      maintainer="ammnt <admin@msftcnsi.com>" \
      org.opencontainers.image.description="Distroless FreeNGINX built with QUIC and HTTP/3 support🚀" \
      org.opencontainers.image.authors="ammnt, admin@msftcnsi.com" \
      org.opencontainers.image.title="Distroless FreeNGINX built with QUIC and HTTP/3 support🚀" \
      org.opencontainers.image.source="https://github.com/ammnt/freenginx/"

STOPSIGNAL SIGQUIT
USER freenginx
CMD ["/usr/sbin/freenginx", "-g", "daemon off;"]
