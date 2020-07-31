#!/bin/bash

set -eu

router="$1"
range_start="$2"
range_end="$3"
lease_ttl="$4"

sed -i 's/^dhcp-option=interface:vlan002,option:dns-server.*/dhcp-option=interface:vlan002,option:dns-server,'"${router}"'/g' /etc/dnsmasq.conf
sed -i 's/^dhcp-option=interface:vlan002,option:ntp-server.*/dhcp-option=interface:vlan002,option:ntp-server,'"${router}"'/g' /etc/dnsmasq.conf
sed -i 's/^dhcp-option=interface:vlan002,option:router.*/dhcp-option=interface:vlan002,option:router,'"${router}"'/g' /etc/dnsmasq.conf
sed -i 's/^dhcp-range=interface:vlan002,.*/dhcp-range=interface:vlan002,'"${range_start},${range_end},${lease_ttl}"'/g' /etc/dnsmasq.conf