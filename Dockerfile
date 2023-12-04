ARG ALPINE_VERSION=3.18

FROM --platform=${TARGETPLATFORM:-linux/amd64} alpine:${ALPINE_VERSION}

RUN apk add --update --no-cache bird && mkdir /etc/bird && mv /etc/bird.conf /etc/bird/bird.conf

CMD ["/usr/sbin/bird", "-c", "/etc/bird/bird.conf", "-f", "-R"]
