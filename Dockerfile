ARG BASE_VERSION=3.21.2
ARG BASE_HASH=56fa17d2a7e7f168a043a2712e63aed1f8543aeafdcee47c58dcffe38ed51099
FROM docker.io/library/alpine:${BASE_VERSION}@sha256:${BASE_HASH} AS builder
ARG OPENSSL_BRANCH=master
ARG APP_BRANCH=release-1.27.4
RUN NB_CORES="${BUILD_CORES-$(getconf _NPROCESSORS_CONF)}" \
&& addgroup --gid 101 -S freenginx && adduser -S freenginx --uid 101 -s /sbin/nologin -G freenginx --no-create-home \
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
&& cd /tmp && git clone -b "${APP_BRANCH}" https://github.com/freenginx/nginx && rm -rf /tmp/nginx/docs/html/* \
&& sed -i -e 's@"nginx/"@" "@g' /tmp/nginx/src/core/nginx.h \
&& sed -i -e 's@"nginx version: "@" "@g' /tmp/nginx/src/core/nginx.c \
&& sed -i -e 's@"freenginx"@" "@g' /tmp/nginx/src/core/nginx.h \
&& sed -i -e 's@"freenginx version: "@" "@g' /tmp/nginx/src/core/nginx.c \
&& sed -i -e 's@r->headers_out.server == NULL@0@g' /tmp/nginx/src/http/ngx_http_header_filter_module.c \
&& sed -i -e 's@r->headers_out.server == NULL@0@g' /tmp/nginx/src/http/v2/ngx_http_v2_filter_module.c \
&& sed -i -e 's@r->headers_out.server == NULL@0@g' /tmp/nginx/src/http/v3/ngx_http_v3_filter_module.c \
&& sed -i -e 's@<hr><center>freenginx</center>@@g' /tmp/nginx/src/http/ngx_http_special_response.c \
&& sed -i -e 's@NGINX_VERSION      ".*"@NGINX_VERSION      " "@g' /tmp/nginx/src/core/nginx.h \
&& git clone --depth=1 --recursive --shallow-submodules https://github.com/nginx/njs && git clone --depth=1 --recursive --shallow-submodules https://github.com/google/ngx_brotli \
&& git clone -b ${OPENSSL_BRANCH} https://boringssl.googlesource.com/boringssl && cd /tmp/boringssl && git checkout --force --quiet e648990 \
&& mkdir -p /tmp/boringssl/build && cmake -B/tmp/boringssl/build -S/tmp/boringssl -DCMAKE_BUILD_TYPE=RelWithDebInfo \
&& make -C/tmp/boringssl/build -j$(getconf _NPROCESSORS_ONLN) && cd /tmp/njs && ./configure && make -j "${NB_CORES}" \
&& make clean && mkdir /var/cache/freenginx && cd /tmp/nginx && ./auto/configure \
    --with-debug \
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
    --with-cc-opt="-O3 -g -m64 -march=westmere -falign-functions=32 -flto -funsafe-math-optimizations -fstack-protector-strong --param=ssp-buffer-size=4 -Wimplicit-fallthrough=0 -Wno-error=strict-aliasing -Wformat -Wno-error=pointer-sign -Wno-implicit-function-declaration -Wno-int-conversion -Wno-error=unused-result -Wno-unused-result -fcode-hoisting -Werror=format-security -Wno-deprecated-declarations -Wp,-D_FORTIFY_SOURCE=2 -DTCP_FASTOPEN=23 -fPIC -I/tmp/boringssl/include" \
    --with-ld-opt="-L/tmp/boringssl/build/ssl -L/tmp/boringssl/build/crypto" \
    --with-compat \
    --with-file-aio \
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
&& make -j "${NB_CORES}" && make install && make clean && strip /usr/sbin/freenginx* \
&& chown -R freenginx:freenginx /var/cache/freenginx && chmod -R g+w /var/cache/freenginx \
&& chown -R freenginx:freenginx /etc/freenginx && chmod -R g+w /etc/freenginx

FROM docker.io/library/alpine:${BASE_VERSION}@sha256:${BASE_HASH}
RUN addgroup -S angie && adduser -S angie -s /sbin/nologin -G angie --uid 101 --no-create-home \
&& apk -U upgrade && apk add --no-cache \
    pcre \
    tini \
    brotli-libs \
    libxslt \
    ca-certificates \
&& update-ca-certificates && apk --purge del ca-certificates libstdc++ libgcc apk-tools \
&& rm -rf /tmp/* /var/cache/apk/ /var/cache/misc /root/.gnupg /root/.cache /root/go /etc/apk

COPY --from=builder /usr/sbin/freenginx /usr/sbin/freenginx
COPY --from=builder /etc/freenginx /etc/freenginx
COPY --from=builder /var/cache/freenginx /var/cache/freenginx
COPY ./freenginx.conf /etc/freenginx/freenginx.conf
COPY ./default.conf /etc/freenginx/conf.d/default.conf

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
