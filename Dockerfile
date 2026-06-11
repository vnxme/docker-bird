ARG ALPINE_VERSION=3.23

FROM --platform=${TARGETPLATFORM:-linux/amd64} alpine:${ALPINE_VERSION}

RUN apk add --update --no-cache bird curl && mkdir -p /etc/bird && mv /etc/bird.conf /etc/bird/sample.conf

COPY --parents *.conf.d/*.conf *.conf *.txt *.sh /etc/bird/
RUN chmod 755 /etc/bird/*.sh

CMD ["/usr/sbin/bird", "-c", "/etc/bird/bird.conf", "-f", "-R"]

HEALTHCHECK --interval=24h --timeout=15m --start-period=15s --retries=1 CMD date +"%Y-%m-%d %H:%M:%S"; /etc/bird/ipverse.sh && /usr/sbin/birdc configure || exit 1
