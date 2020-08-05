#!/bin/bash

set -eu

if [ $# -lt 3 ]; then
    echo >&2 "usage: sicfg-pxe-lan0 ROUTER_IP DHCP_RANGE_START_IP DHCP_RANGE_END_IP [DHCP_LEASE_TTL]"
    exit 1
fi
router="$1"
range_start="$2"
range_end="$3"
lease_ttl="${4:-10m}"

sed -i 's/^dhcp-option=interface:lan0,option:dns-server.*/dhcp-option=interface:lan0,option:dns-server,'"${router}"'/g' /etc/dnsmasq.conf
sed -i 's/^dhcp-option=interface:lan0,option:ntp-server.*/dhcp-option=interface:lan0,option:ntp-server,'"${router}"'/g' /etc/dnsmasq.conf
sed -i 's/^dhcp-option=interface:lan0,option:router.*/dhcp-option=interface:lan0,option:router,'"${router}"'/g' /etc/dnsmasq.conf
sed -i 's/^dhcp-range=interface:lan0,.*/dhcp-range=interface:lan0,'"${range_start},${range_end},${lease_ttl}"'/g' /etc/dnsmasq.conf