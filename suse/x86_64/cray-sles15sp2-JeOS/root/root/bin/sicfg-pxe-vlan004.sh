#!/bin/bash

set -eu

if [ $# -lt 3 ]; then
cat << EOM >&2
  usage: sicfg-pxe-vlan004.sh ROUTER_IP DHCP_RANGE_START_IP DHCP_RANGE_END_IP [DHCP_LEASE_TTL]
  i.e.: sicfg-pxe-vlan004.sh 10.254.1.1 10.254.2.1 10.254.127.254 10m
EOM
  exit 1
fi
router="$1"
range_start="$2"
range_end="$3"
lease_ttl="${4:-10m}"

sed -i 's/^dhcp-option=interface:vlan004,option:dns-server.*/dhcp-option=interface:vlan004,option:dns-server,'"${router}"'/g' /etc/dnsmasq.conf
sed -i 's/^dhcp-option=interface:vlan004,option:ntp-server.*/dhcp-option=interface:vlan004,option:ntp-server,'"${router}"'/g' /etc/dnsmasq.conf
sed -i 's/^dhcp-option=interface:vlan004,option:router.*/dhcp-option=interface:vlan004,option:router,'"${router}"'/g' /etc/dnsmasq.conf
sed -i 's/^dhcp-range=interface:vlan004,.*/dhcp-range=interface:vlan004,'"${range_start},${range_end},${lease_ttl}"'/g' /etc/dnsmasq.conf