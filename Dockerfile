FROM tarantool/tarantool:2.6.0

RUN set -eux; \
    apk add --no-cache \
        curl \
        gcc \
        g++ \
        make \
        cmake \
        unzip \
        git \
    ; \
    tarantoolctl rocks install http

COPY init.lua /opt/tarantool/init.lua

EXPOSE 8080/tcp

CMD ["tarantool", "/opt/tarantool/init.lua"]