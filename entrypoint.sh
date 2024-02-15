#!/bin/sh

cleanup() {
    kill "${bird_pid}"
    kill "${zerotier_pid}"
    exit 0
}

trap cleanup TERM

/usr/sbin/bird -c ${BIRD_CONFIG_PATH:-/etc/bird/bird.conf} -f -R ${BIRD_CUSTOM_ARGS:-} &
bird_pid=$!

/zerotier.sh $@ &
zerotier_pid=$!

wait ${zerotier_pid}
