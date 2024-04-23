#!/bin/sh

hooks() {
    for file in /app/hooks/$1/*.sh; do
        [ -f "$file" ] && [ -x "$file" ] && "$file"
    done
}

cleanup() {
    kill "${bird_pid}"
    kill "${zerotier_pid}"
    hooks "down"
    exit 0
}

trap cleanup TERM

hooks "up"

/usr/sbin/bird -c ${BIRD_CONFIG_PATH:-/etc/bird/bird.conf} -f -R ${BIRD_CUSTOM_ARGS:-} &
bird_pid=$!

/app/zerotier.sh $@ &
zerotier_pid=$!

wait ${zerotier_pid}
