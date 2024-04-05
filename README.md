# FreeNGINX with HTTP/3 and QUIC support🚀

The Docker image is ready to use:<br>
<code>docker run -d --rm -p 127.0.0.1:8080:8080/tcp ghcr.io/ammnt/freenginx:http3</code><br>
or<br>
<code>docker run -d --rm -p 127.0.0.1:8080:8080/tcp ammnt/freenginx:http3</code>

# Description:

- Based on latest version of Alpine Linux - low size (~4 MB);
- BoringSSL with HTTP/3 and QUIC support;
- HTTP/2 with ALPN support;
- TLS 1.3 and 0-RTT support;
- TLS 1.2 and TCP Fast Open (TFO) support;
- Built using hardening GCC flags;
- NJS support;
- PCRE with JIT compilation;
- zlib library latest version;
- Rootless master process - unprivileged container;
- Async I/O threads module;
- "Distroless" image - shell removed from the image;
- Removed unnecessary modules;
- Added OCI labels and annotations;
- No excess ENTRYPOINT in the image;
- Slimmed version by Docker Slim tool;
- Anonymous signature - removed "Server" header ("banner"):<br>
https://github.com/ammnt/freenginx/blob/http3/Dockerfile

# Note:

Feel free to <a href="https://github.com/ammnt/freenginx/issues/new">contact me</a> with more security improvements🙋
