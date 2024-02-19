# docker-bird
A set of Docker images of BIRD & OpenVPN

### Features
- Launches 2 binaries on boot
- Picks a random \*.conf or \*.ovpn in the config dir by default
- Includes iptables/ip6tables for advanced configuration (e.g. NAT)

### Environment
| Variable            | Default Value       | Comment                       |
|---------------------|---------------------|-------------------------------|
| BIRD_CONFIG_PATH    | /etc/bird/bird.conf |                               |
| BIRD_CUSTOM_ARGS    |                     | Added after -c, -f and -R     |
| OPENVPN_CONFIG_DIR  | /etc/openvpn        |                               |
| OPENVPN_CONFIG_FILE |                     |                               |
| OPENVPN_CUSTOM_ARGS |                     | Added after --cd and --config |

### Credits
- OpenVPN Client Entrypoint - [wfg/docker-openvpn-client](https://github.com/wfg/docker-openvpn-client/blob/master/build/entry.sh)
