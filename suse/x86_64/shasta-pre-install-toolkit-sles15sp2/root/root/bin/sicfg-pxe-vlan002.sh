#!/bin/bash

set -eu

if [ $# -lt 3 ]; then
cat << EOM >&2
  usage: sicfg-pxe-vlan002.sh ROUTER_IP DHCP_RANGE_START_IP DHCP_RANGE_END_IP [DHCP_LEASE_TTL]
  i.e.: sicfg-pxe-vlan002.sh 10.252.1.1 10.252.2.1 10.252.127.254 10m
EOM
  exit 1
fi
router="$1"
range_start="$2"
range_end="$3"
lease_ttl="${4:-10m}"

cat << EOF > /etc/dnsmasq.d/nmn.conf
# NMN:
domain=/spit.nmn/
interface=vlan002
dhcp-option=interface:vlan002,option:dns-server,${router}
dhcp-option=interface:vlan002,option:ntp-server,${router}
dhcp-option=interface:vlan002,option:router,${router}
dhcp-range=interface:vlan002,${range_start},${range_end},${lease_ttl}
EOF
if [[ ! $(grep ${router} /etc/sysconfig/network/config | grep NETCONFIG_DNS_STATIC_SERVERS) ]]; then
  sed -E -i 's/NETCONFIG_DNS_STATIC_SERVERS="(.*)"/NETCONFIG_DNS_STATIC_SERVERS='"$router"' \1"/' /etc/sysconfig/network/config
  netconfig update -f
fi
sed -i 's/^set cloud-init .*/set cloud-init ds=nocloud-net\;s='"${router}"':8888' /var/www/ipxe.script
systemctl restart dnsmasq
