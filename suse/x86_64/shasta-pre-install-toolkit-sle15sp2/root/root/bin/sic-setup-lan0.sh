#!/bin/bash

set -eu
set +x
if [ $# -lt 2 ]; then
cat << EOM >&2
  usage: sic-setup-lan0.sh CIDR|IP/MASQ GATEWAY DEVICE DNS1 DNS2
  i.e.: sic-setup-lan0.sh 172.29.16.5/20 172.29.16.1 172.38.84.40 em1 [em2]
EOM
  exit 1
fi
cidr="$1" && shift
gateway="$1" && shift
dns="$1" && shift
addr="$(echo $cidr | cut -d '/' -f 1)"
mask="$(echo $cidr | cut -d '/' -f 2)"
sed -i 's/^IPADDR=.*/IPADDR="'"${addr}"'\/'"${mask}"'"/g' /etc/sysconfig/network/ifcfg-lan0
sed -i 's/^PREFIXLEN=.*/PREFIXLEN="'"${mask}"'"/g' /etc/sysconfig/network/ifcfg-lan0
sed -i 's/^BRIDGE_PORTS=.*/BRIDGE_PORTS="'"$*"'"/g' /etc/sysconfig/network/ifcfg-lan0
echo "default $gateway - -" >/etc/sysconfig/network/ifroute-lan0
sed -i 's/NETCONFIG_DNS_STATIC_SERVERS=.*/NETCONFIG_DNS_STATIC_SERVERS="'"${dns:-9.9.9.9}"'"/' /etc/sysconfig/network/config
printf '% -15s % -65s\n' "$addr" 'packages.local packages #${AUTOMATION}' >> /etc/hosts
netconfig update -f
wicked ifreload lan0
systemctl restart wickedd-nanny # Shake out daemon handling of new lan0 name.
