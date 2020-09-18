#!/bin/bash

set -eu

if [ $# -lt 3 ]; then
cat << EOM >&2
  usage: sic-pxe-vlan002.sh ROUTER_IP DHCP_RANGE_START_IP DHCP_RANGE_END_IP [DHCP_LEASE_TTL]
  i.e.: sic-pxe-vlan002.sh 10.252.1.1 10.252.2.1 10.252.127.254 10m
EOM
  exit 1
fi
router="$1"
range_start="$2"
range_end="$3"
lease_ttl="${4:-10m}"

cat << EOF > /etc/dnsmasq.d/nmn.conf
# NMN:
server=/nmn/${router}
address=/nmn/${router}
domain=nmn,${range_start},${range_end},local
dhcp-option=interface:vlan002,option:domain-search,nmn
interface=vlan002
dhcp-option=interface:vlan002,option:dns-server,${router}
dhcp-option=interface:vlan002,option:ntp-server,${router}
dhcp-option=interface:vlan002,option:router,${router}
dhcp-range=interface:vlan002,${range_start},${range_end},${lease_ttl}
EOF
systemctl restart dnsmasq
