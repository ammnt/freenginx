FROM docker.io/library/alpine:latest
RUN NB_CORES="${BUILD_CORES-$(getconf _NPROCESSORS_CONF)}" \
&& apk -U upgrade && apk add --no-cache \
    openssl \
    pcre \
    zlib-ng \
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
    zlib-ng-dev \
    binutils \
    gnupg \
    cmake \
    go \
    libxslt \
    libxslt-dev \
    tini \
    musl-dev \
    ncurses-libs \
&& cd /tmp && git clone https://github.com/freenginx/nginx \
&& sed -i -e 's@"freenginx"@" "@g' /tmp/nginx/src/core/nginx.h \
&& sed -i -e 's@"freenginx version: "@" "@g' /tmp/nginx/src/core/nginx.c \
&& sed -i -e 's@r->headers_out.server == NULL@0@g' /tmp/nginx/src/http/ngx_http_header_filter_module.c \
&& sed -i -e 's@r->headers_out.server == NULL@0@g' /tmp/nginx/src/http/v2/ngx_http_v2_filter_module.c \
&& sed -i -e 's@r->headers_out.server == NULL@0@g' /tmp/nginx/src/http/v3/ngx_http_v3_filter_module.c \
&& sed -i -e 's@<hr><center>freenginx</center>@@g' /tmp/nginx/src/http/ngx_http_special_response.c \
&& sed -i -e 's@NGINX_VERSION      ".*"@NGINX_VERSION      " "@g' /tmp/nginx/src/core/nginx.h \
&& sed -i -e 's/listen       80;/listen 8080;/g' /tmp/nginx/conf/nginx.conf \
&& sed -i -e 's@#tcp_nopush     on;@client_body_temp_path /tmp/client_temp;@g' /tmp/nginx/conf/nginx.conf \
&& sed -i -e 's@#keepalive_timeout  0;@proxy_temp_path /tmp/proxy_temp;@g' /tmp/nginx/conf/nginx.conf \
&& sed -i -e 's@#gzip  on;@fastcgi_temp_path /tmp/fastcgi_temp;@g' /tmp/nginx/conf/nginx.conf \
&& sed -i -e '1i pid /tmp/freenginx.pid;\n' /tmp/nginx/conf/nginx.conf \
&& addgroup --gid 101 -S freenginx && adduser -S freenginx --uid 101 -s /sbin/nologin -G freenginx --no-create-home \
&& git clone --depth=1 --recursive --shallow-submodules https://github.com/nginx/njs && git clone https://boringssl.googlesource.com/boringssl \
&& cd boringssl && mkdir build && cd /tmp/boringssl/build && cmake -DBUILD_SHARED_LIBS=1 .. \
&& make && mkdir -p /tmp/boringssl/.openssl/lib && cd /tmp/boringssl/.openssl && ln -s ../include include \
&& cd /tmp/boringssl && cp build/crypto/libcrypto.so .openssl/lib && cp build/ssl/libssl.so .openssl/lib \
&& cp /tmp/boringssl/.openssl/lib/libssl.so /usr/lib/ && cp /tmp/boringssl/.openssl/lib/libcrypto.so /usr/lib \
&& touch /tmp/boringssl/.openssl/include/openssl/ssl.h && cd /tmp/njs && ./configure \
&& make -j "${NB_CORES}" && make clean && mkdir /var/cache/freenginx && cd /tmp/nginx && ./auto/configure \
    --with-debug \
    --prefix=/etc/freenginx \
    --sbin-path=/usr/sbin/freenginx \
    --user=freenginx \
    --group=freenginx \
    --http-log-path=/tmp/access.log \
    --error-log-path=/tmp/error.log \
    --conf-path=/etc/freenginx/nginx.conf \
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
&& make -j "${NB_CORES}" && make install && make clean && strip /usr/sbin/freenginx* \
&& chown -R freenginx:freenginx /var/cache/freenginx && chmod -R g+w /var/cache/freenginx \
&& chown -R freenginx:freenginx /etc/nginx && chmod -R g+w /etc/freenginx \
&& update-ca-certificates && apk --purge del libgcc musl-dev g++ make build-base linux-headers automake autoconf git talloc talloc-dev libtool zlib-ng-dev binutils gnupg cmake go pcre-dev ca-certificates openssl libxslt-dev apk-tools \
&& rm -rf /tmp/* /var/cache/apk/ /var/cache/misc /root/.gnupg /root/.cache /root/go /etc/apk \
&& ln -sf /dev/stdout /tmp/access.log && ln -sf /dev/stderr /tmp/error.log

COPY ./nginx.conf /etc/freenginx/nginx.conf
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
