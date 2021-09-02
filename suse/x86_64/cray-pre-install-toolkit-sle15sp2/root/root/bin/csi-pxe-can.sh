#!/bin/bash

set -eu

if [ $# -lt 3 ]; then
cat << EOM >&2
  usage: csi-pxe-can.sh ROUTER_IP DHCP_RANGE_START_IP DHCP_RANGE_END_IP [DHCP_LEASE_TTL]
  i.e.: csi-pxe-can.sh 10.102.9.111 10.102.9.4 10.102.9.109 10m
EOM
  exit 1
fi
router="$1"
range_start="$2"
range_end="$3"
lease_ttl="${4:-10m}"

cat << EOF > /etc/dnsmasq.d/can.conf
# CAN:
server=/can/
address=/can/
dhcp-option=interface:bond0.can0,option:domain-search,can
interface-name=pit.can,bond0.can0
interface=bond0.can0
cname=packages.can,pit.can
cname=registry.can,pit.can
dhcp-option=interface:bond0.can0,option:router,${router%/*}
dhcp-range=interface:bond0.can0,${range_start},${range_end},${lease_ttl}
EOF

systemctl restart dnsmasq
