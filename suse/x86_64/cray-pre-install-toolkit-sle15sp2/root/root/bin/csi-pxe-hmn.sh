#!/bin/bash

set -eu

if [ $# -lt 3 ]; then
cat << EOM >&2
  usage: csi-pxe-hmn.sh ROUTER_IP DHCP_RANGE_START_IP DHCP_RANGE_END_IP [DHCP_LEASE_TTL]
  i.e.: csi-pxe-hmn.sh 10.254.1.1 10.254.2.1 10.254.127.254 10m
EOM
  exit 1
fi
router="$1"
range_start="$2"
range_end="$3"
lease_ttl="${4:-10m}"

cat << EOF > /etc/dnsmasq.d/hmn.conf
# HMN:
server=/hmn/
address=/hmn/
domain=hmn,${range_start},${range_end},local
interface-name=pit.hmn,bond0.hmn0
dhcp-option=interace:bond0.hmn0,option:domain-search,hmn
interface=bond0.hmn0
cname=packages.hmn,pit.hmn
cname=registry.hmn,pit.hmn
dhcp-option=interface:bond0.hmn0,option:dns-server,${router%/*}
dhcp-option=interface:bond0.hmn0,option:ntp-server,${router%/*}
dhcp-option=interface:bond0.hmn0,option:router,${router%/*}
dhcp-range=interface:bond0.hmn0,${range_start},${range_end},${lease_ttl}
EOF
systemctl restart dnsmasq
