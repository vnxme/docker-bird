# docker-bird
A set of Docker images of BIRD & ZeroTier

### Features
- Launches 2 binaries on boot
- Supports joining multiple networks
- Includes iptables/ip6tables for advanced configuration (e.g. NAT)

### Environment
| Variable                 | Default Value         | Comment                        |
|--------------------------|-----------------------|--------------------------------|
| BIRD_CONFIG_PATH         | /etc/bird/bird.conf   |                                |
| BIRD_CUSTOM_ARGS         |                       | Added after -c, -f and -R      |
| ZEROTIER_API_SECRET      |                       | Written to authtoken.secret    |
| ZEROTIER_CONFIG_DIR      | /var/lib/zerotier-one |                                |
| ZEROTIER_CUSTOM_ARGS     |                       |                                |
| ZEROTIER_IDENTITY_PUBLIC |                       | Written to identity.public     |
| ZEROTIER_IDENTITY_SECRET |                       | Written to identity.secret     |
| ZEROTIER_JOIN_NETWORKS   |                       | {X}.conf created in networks.d |
| ZEROTIER_PRIMARY_PORT    | 9993                  | Written to zerotier-one.port   |

### Credits:
- Zerotier Dockerfile - [zerotier/ZeroTierOne](https://github.com/zerotier/ZeroTierOne/blob/dev/Dockerfile.release)
- Zerotier Entrypoint - [zerotier/ZeroTierOne](https://github.com/zerotier/ZeroTierOne/blob/dev/entrypoint.sh.release)
- Zerotier for Alpine - [zyclonite/zerotier-docker](https://github.com/zyclonite/zerotier-docker/blob/main/Dockerfile)
