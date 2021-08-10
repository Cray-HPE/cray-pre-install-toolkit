#!/bin/bash

set -eu

if [ $# -lt 3 ]; then
cat << EOM >&2
  usage: csi-pxe-nmn.sh ROUTER_IP DHCP_RANGE_START_IP DHCP_RANGE_END_IP [DHCP_LEASE_TTL]
  i.e.: csi-pxe-nmn.sh 10.252.1.1 10.252.2.1 10.252.127.254 10m
EOM
  exit 1
fi
router="$1"
range_start="$2"
range_end="$3"
lease_ttl="${4:-10m}"

cat << EOF > /etc/dnsmasq.d/nmn.conf
# NMN:
server=/nmn/
address=/nmn/
interface-name=pit.nmn,bond0.nåmn0
domain=nmn,${range_start},${range_end},local
dhcp-option=interface:bond0.nåmn0,option:domain-search,nmn
interface=bond0.nåmn0
cname=packages.nmn,pit.nmn
cname=registry.nmn,pit.nmn
dhcp-option=interface:bond0.nåmn0,option:dns-server,${router%/*}
dhcp-option=interface:bond0.nåmn0,option:ntp-server,${router%/*}
dhcp-option=interface:bond0.nåmn0,option:router,${router%/*}
dhcp-range=interface:bond0.nåmn0,${range_start},${range_end},${lease_ttl}
EOF
systemctl restart dnsmasq
