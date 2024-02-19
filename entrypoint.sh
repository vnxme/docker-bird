#!/bin/sh

cleanup() {
    kill "${bird_pid}"
   	kill "${openvpn_pid}"
    exit 0
}

trap cleanup TERM

/usr/sbin/bird -c ${BIRD_CONFIG_PATH:-/etc/bird/bird.conf} -f -R ${BIRD_CUSTOM_ARGS:-} &
bird_pid=$!

/openvpn.sh "$@" &
openvpn_pid=$!

wait $openvpn_pid
