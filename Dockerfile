ARG NGINX_VERSION=1.22.1
ARG MODSECURITY_VERSION=3.0.8
ARG MOD_SECURITY_NGINX_VERSION=1.0.3
ARG CORE_RULE_SET_VERSION=3.3.4

FROM nginx:$NGINX_VERSION as build

ARG NGINX_VERSION
ARG MODSECURITY_VERSION
ARG MOD_SECURITY_NGINX_VERSION

RUN apt update && apt install -y \
        git \
        g++ \
        apt-utils \
        autoconf \
        automake \
        build-essential \
        libcurl4-openssl-dev \
        libgeoip-dev \
        liblmdb-dev \
        libpcre++-dev \
        libtool \
        libxml2-dev \
        libyajl-dev \
        pkgconf \
        wget \
        zlib1g-dev && \
    rm -rf /var/lib/apt/lists/*

RUN cd /opt && \
    git clone https://github.com/SpiderLabs/ModSecurity && \
    cd ModSecurity/ && \
    git checkout "v$MODSECURITY_VERSION" && \
    git submodule init && \
    git submodule update && \
    sh build.sh && \
    ./configure && \
    make && \
    make install

RUN apt update && apt install -y libssl-dev

RUN cd /opt && \
    git clone --depth 1 https://github.com/SpiderLabs/ModSecurity-nginx.git && \
    cd ModSecurity-nginx && \
    git checkout "v$MOD_SECURITY_NGINX_VERSION"

RUN wget https://nginx.org/download/nginx-$NGINX_VERSION.tar.gz && \
    tar vxf nginx-$NGINX_VERSION.tar.gz && \
    cd nginx-$NGINX_VERSION && \
    ./configure --add-dynamic-module=/opt/ModSecurity-nginx \
    --prefix=/etc/nginx --sbin-path=/usr/sbin/nginx --modules-path=/usr/lib/nginx/modules --conf-path=/etc/nginx/nginx.conf --error-log-path=/var/log/nginx/error.log --http-log-path=/var/log/nginx/access.log --pid-path=/var/run/nginx.pid --lock-path=/var/run/nginx.lock --http-client-body-temp-path=/var/cache/nginx/client_temp --http-proxy-temp-path=/var/cache/nginx/proxy_temp --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp --http-scgi-temp-path=/var/cache/nginx/scgi_temp --user=nginx --group=nginx --with-compat --with-file-aio --with-threads --with-http_addition_module --with-http_auth_request_module --with-http_dav_module --with-http_flv_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_mp4_module --with-http_random_index_module --with-http_realip_module --with-http_secure_link_module --with-http_slice_module --with-http_ssl_module --with-http_stub_status_module --with-http_sub_module --with-http_v2_module --with-mail --with-mail_ssl_module --with-stream --with-stream_realip_module --with-stream_ssl_module --with-stream_ssl_preread_module --with-cc-opt='-g -O2 -ffile-prefix-map=/data/builder/debuild/nginx-$NGINX_VERSION/debian/debuild-base/nginx-$NGINX_VERSION=. -fstack-protector-strong -Wformat -Werror=format-security -Wp,-D_FORTIFY_SOURCE=2 -fPIC' --with-ld-opt='-lpcre -Wl,-z,relro -Wl,-z,now -Wl,--as-needed -pie' && \
    make modules

FROM nginx:$NGINX_VERSION

ARG NGINX_VERSION
ARG CORE_RULE_SET_VERSION

COPY --from=build /nginx-$NGINX_VERSION/objs/ngx_http_modsecurity_module.so /etc/nginx/modules/
COPY --from=build /opt/ModSecurity/modsecurity.conf-recommended /etc/nginx/modsecurity.conf
COPY --from=build /opt/ModSecurity/unicode.mapping /etc/nginx/
COPY --from=build /usr/local/modsecurity /usr/local/modsecurity

RUN apt update && apt install -y \
        libyajl2 && \
    rm -rf /var/lib/apt/lists/*

RUN sed -i "1 i\load_module /etc/nginx/modules/ngx_http_modsecurity_module.so;" /etc/nginx/nginx.conf
RUN sed -i "/^http {/a modsecurity_rules_file /etc/nginx/modsecurity.conf;" /etc/nginx/nginx.conf
RUN sed -i "/^http {/a modsecurity on;" /etc/nginx/nginx.conf

RUN mkdir -p /etc/nginx/modsecurity.d && \
    cd /etc/nginx/modsecurity.d && \
    curl https://github.com/coreruleset/coreruleset/archive/refs/tags/v$CORE_RULE_SET_VERSION.tar.gz -O -J -L && \
    tar -xvf coreruleset-$CORE_RULE_SET_VERSION.tar.gz coreruleset-$CORE_RULE_SET_VERSION/rules  --strip-components 1 && \
    rm -rf coreruleset-$CORE_RULE_SET_VERSION.tar.gz

RUN find /etc/nginx/modsecurity.d/rules -maxdepth 1 -type f -name "*.conf" -printf 'include modsecurity.d/rules/%f\n' >> /etc/nginx/modsecurity.conf

