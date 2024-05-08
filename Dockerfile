ARG ALPINE_VERSION=3.19

FROM --platform=${TARGETPLATFORM:-linux/amd64} alpine:${ALPINE_VERSION}

RUN apk add --update --no-cache --purge --clean-protected libcap bird curl iproute2 iptables iptables-legacy iputils-ping net-tools openvpn \
	&& mkdir /etc/bird && mv /etc/bird.conf /etc/bird/bird.conf \
	&& rm -rf /var/cache/apk/* && mkdir -p /app/hooks/up /app/hooks/down

COPY entrypoint.sh openvpn.sh /app/
RUN chmod 755 /app/*.sh

CMD []
ENTRYPOINT ["/app/entrypoint.sh"]
