#!/bin/bash

set -eu

if [ $# -lt 3 ]; then
cat << EOM >&2
  usage: sic-pxe-bond0.sh ROUTER_IP DHCP_RANGE_START_IP DHCP_RANGE_END_IP [DHCP_LEASE_TTL]
  i.e.: sic-pxe-bond0.sh 10.1.1.1 10.1.2.1 10.1.255.254 10m
EOM
  exit 1
fi
router="$1"
range_start="$2"
range_end="$3"
lease_ttl="${4:-10m}"

cat << EOF > /etc/dnsmasq.d/mtl.conf
# MTL:
domain=mtl,${range_start},${range_end},local
interface=bond0
dhcp-option=interface:bond0,option:dns-server,${router}
dhcp-option=interface:bond0,option:ntp-server,${router}
dhcp-option=interface:bond0,option:router,${router}
dhcp-range=interface:bond0,${range_start},${range_end},${lease_ttl}
EOF
systemctl restart dnsmasq