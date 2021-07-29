#!/bin/bash

set -eu
if [ $# -lt 1 ]; then
cat << EOM >&2
  usage: csi-setup-vlan002.sh CIDR|IP/MASQ
  i.e.: csi-setup-vlan002.sh 10.252.1.1/17
EOM
  exit 1
fi
cidr="$1"
addr="$(echo $cidr | cut -d '/' -f 1)"
mask="$(echo $cidr | cut -d '/' -f 2)"
sed -i 's/^IPADDR=.*/IPADDR="'"${addr}"'\/'"${mask}"'"/g' /etc/sysconfig/network/ifcfg-vlan002
sed -i 's/^PREFIXLEN=.*/PREFIXLEN="'"${mask}"'"/g' /etc/sysconfig/network/ifcfg-vlan002
wicked ifreload vlan002