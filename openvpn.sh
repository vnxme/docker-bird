#!/bin/sh

cleanup() {
    kill "${openvpn_pid}"
    exit 0
}

trap cleanup TERM

openvpn_cd="${OPENVPN_CONFIG_DIR:-/etc/openvpn}"

if [ -n "${OPENVPN_CONFIG_FILE}" ]; then
    openvpn_cf=$(find "${openvpn_cd}" -name "${OPENVPN_CONFIG_FILE}" 2> /dev/null | sort | shuf -n 1)
else
    openvpn_cf=$(find "${openvpn_cd}" -name '*.conf' -o -name '*.ovpn' 2> /dev/null | sort | shuf -n 1)
fi

if [ -z "${openvpn_cf}" ]; then
    echo "no openvpn configuration file found" >&2
    exit 1
fi

echo "using openvpn configuration file: ${openvpn_cf}"

/usr/sbin/openvpn --cd "${openvpn_cd}" --config "${openvpn_cf}" ${OPENVPN_CUSTOM_ARGS:-} &
openvpn_pid=$!

wait ${openvpn_pid}
