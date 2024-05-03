ARG ALPINE_VERSION=3.19
ARG ZT_COMMIT=fcaf008beb1dfc8bc69b5305d27ad1b12b9412a5

FROM --platform=${BUILDPLATFORM:-linux/amd64} alpine:${ALPINE_VERSION} as builder

ARG ZT_COMMIT

RUN apk add --update alpine-sdk cargo linux-headers openssl-dev \
    && git clone --quiet https://github.com/zerotier/ZeroTierOne.git /src \
    && git -C src reset --quiet --hard ${ZT_COMMIT} \
    && cd /src \
    && make -f make-linux.mk

FROM --platform=${TARGETPLATFORM:-linux/amd64} alpine:${ALPINE_VERSION}

COPY --from=builder /src/zerotier-one /usr/sbin/

RUN apk add --no-cache --purge --clean-protected libc6-compat libstdc++ bird curl iproute2 iptables iptables-legacy net-tools iputils-ping openssl \
    && mkdir -p /etc/bird && mv /etc/bird.conf /etc/bird/bird.conf \
    && ln -s /usr/sbin/zerotier-one /usr/sbin/zerotier-idtool \
    && ln -s /usr/sbin/zerotier-one /usr/sbin/zerotier-cli \
    && rm -rf /var/cache/apk/* && mkdir -p /app/hooks/up /app/hooks/down

COPY entrypoint.sh zerotier.sh /app/
RUN chmod 755 /app/*.sh

HEALTHCHECK --interval=1s CMD /bin/sh /app/healthcheck.sh

CMD []
ENTRYPOINT ["/app/entrypoint.sh"]
