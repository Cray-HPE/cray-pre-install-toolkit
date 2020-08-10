#!/bin/bash

set -eu
set +x
if [ $# -lt 2 ]; then
cat << EOM >&2
  usage: sicfg-nic-lan1.sh CIDR|IP/MASQ GATEWAY DEVICE
  i.e.: sicfg-nic-lan1.sh 172.29.16.5/20 172.29.16.1 em1
EOM
  exit 1
fi
cidr="$1" && shift
gateway="$1" && shift
addr="$(echo $cidr | cut -d '/' -f 1)"
mask="$(echo $cidr | cut -d '/' -f 2)"
sed -i 's/^IPADDR=.*/IPADDR="'"${addr}"'\/'"${mask}"'"/g' /etc/sysconfig/network/ifcfg-lan1
sed -i 's/^PREFIXLEN=.*/PREFIXLEN="'"${mask}"'"/g' /etc/sysconfig/network/ifcfg-lan1
sed -i 's/^BRIDGE_PORTS=.*/BRIDGE_PORTS="'"$*"'"/g' /etc/sysconfig/network/ifcfg-lan1
echo "default $gateway - -" >/etc/sysconfig/network/ifroute-lan1
wicked ifreload lan1