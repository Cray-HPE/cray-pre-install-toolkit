#!/bin/bash

set -eu

if [ $# -lt 3 ]; then
cat << EOM >&2
  usage: sic-pxe-vlan004.sh ROUTER_IP DHCP_RANGE_START_IP DHCP_RANGE_END_IP [DHCP_LEASE_TTL]
  i.e.: sic-pxe-vlan004.sh 10.254.1.1 10.254.2.1 10.254.127.254 10m
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
interface-name=spit.hmn,vlan004
dhcp-option=interace:vlan004,option:domain-search,hmn
interface=vlan004
cname=packages.hmn,spit.hmn
cname=registry.hmn,spit.hmn
dhcp-option=interface:vlan004,option:dns-server,${router%/*}
dhcp-option=interface:vlan004,option:ntp-server,${router%/*}
dhcp-option=interface:vlan004,option:router,${router%/*}
dhcp-range=interface:vlan004,${range_start},${range_end},${lease_ttl}
EOF
systemctl restart dnsmasq
