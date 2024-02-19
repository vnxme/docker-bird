ARG ALPINE_VERSION=3.18

FROM --platform=${TARGETPLATFORM:-linux/amd64} alpine:${ALPINE_VERSION}

RUN apk add --update --no-cache --purge --clean-protected bird curl iproute2 iptables ip6tables net-tools iputils-ping openvpn \
	&& mkdir /etc/bird && mv /etc/bird.conf /etc/bird/bird.conf \
	&& rm -rf /var/cache/apk/*

COPY entrypoint.sh openvpn.sh /
RUN chmod 755 /entrypoint.sh /openvpn.sh

CMD []
ENTRYPOINT ["/entrypoint.sh"]
