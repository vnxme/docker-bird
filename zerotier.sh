#!/bin/sh

zerotier_cd=${ZEROTIER_CONFIG_DIR:-/var/lib/zerotier-one}
zerotier_pf="${zerotier_cd}/zerotier-one.pid"

grepzt() {
  [ -f ${zerotier_pf} -a -n "$(cat ${zerotier_pf} 2>/dev/null)" -a -d "/proc/$(cat ${zerotier_pf} 2>/dev/null)" ]
  return $?
}

mkztfile() {
  file=$1
  mode=$2
  content=$3

  mkdir -p ${zerotier_cd}
  echo "$content" > "${zerotier_cd}/${file}"
  chmod "$mode" "${zerotier_cd}/${file}"
}

if [ -n "${ZEROTIER_API_SECRET}" ]
then
  mkztfile authtoken.secret 0600 "${ZEROTIER_API_SECRET}"
fi

if [ -n "${ZEROTIER_IDENTITY_PUBLIC}" ]
then
  mkztfile identity.public 0644 "$ZEROTIER_IDENTITY_PUBLIC"
fi

if [ -n "${ZEROTIER_IDENTITY_SECRET}" ]
then
  mkztfile identity.secret 0600 "${ZEROTIER_IDENTITY_SECRET}"
fi

mkztfile zerotier-one.port 0600 "${ZEROTIER_PRIMARY_PORT:-9993}"

killzerotier() {
  log "Killing zerotier"
  kill $(cat ${zerotier_pf} 2>/dev/null)
  exit 0
}

log_header() {
  echo -n "\r=>"
}

log_detail_header() {
  echo -n "\r===>"
}

log() {
  echo "$(log_header)" "$@"
}

log_params() {
  title=$1
  shift
  log "$title" "[$@]"
}

log_detail() {
  echo "$(log_detail_header)" "$@"
}

log_detail_params() {
  title=$1
  shift
  log_detail "$title" "[$@]"
}

trap killzerotier INT TERM

log "Configuring networks to join"
mkdir -p ${zerotier_cd}/networks.d

log_params "Joining networks from command line:" $@
for i in "$@"
do
  log_detail_params "Configuring join:" "$i"
  touch "${zerotier_cd}/networks.d/${i}.conf"
done

if [ -n "${ZEROTIER_JOIN_NETWORKS}" ]
then
  log_params "Joining networks from environment:" ${ZEROTIER_JOIN_NETWORKS}
  for i in ${ZEROTIER_JOIN_NETWORKS}
  do
    log_detail_params "Configuring join:" "$i"
    touch "${zerotier_cd}/networks.d/${i}.conf"
  done
fi

log "Starting ZeroTier"
nohup /usr/sbin/zerotier-one ${ZEROTIER_CUSTOM_ARGS:-} &
zerotier_pid=$!

while ! grepzt
do
  log_detail "ZeroTier hasn't started, waiting a second"

  if [ -f nohup.out ]
  then
    tail -n 10 nohup.out
  fi

  sleep 1
done

log_params "Writing healthcheck for networks:" $@

cat >/healthcheck.sh <<EOF
#!/bin/sh
for i in $@ ${ZEROTIER_JOIN_NETWORKS}
do
  [ "\$(zerotier-cli get \$i status)" = "OK" ] || exit 1
done
EOF

chmod +x /healthcheck.sh

log_params "zerotier-cli info:" "$(zerotier-cli info)"

wait ${zerotier_pid}
