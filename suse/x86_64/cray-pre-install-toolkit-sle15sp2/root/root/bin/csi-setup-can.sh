#!/bin/bash

set -eu
if [ $# -lt 1 ]; then
cat << EOM >&2
  usage: csi-setup-can.sh CIDR|IP/MASQ VLAN_ID
  i.e.: csi-setup-can.sh 10.102.9.110/24 7
EOM
  exit 1
fi
cidr="$1"
addr="$(echo $cidr | cut -d '/' -f 1)"
mask="$(echo $cidr | cut -d '/' -f 2)"
vlan="$(echo $cidr | cut -d '/' -f 3)"
sed -i 's/^IPADDR=.*/IPADDR="'"${addr}"'\/'"${mask}"'"/g' /etc/sysconfig/network/ifcfg-bond0.can0
sed -i 's/^PREFIXLEN=.*/PREFIXLEN="'"${mask}"'"/g' /etc/sysconfig/network/ifcfg-bond0.can0\
sed -i 's/^VLANID=.*/VLANID="'"${vlan:-7}"'"/g' /etc/sysconfig/network/ifcfg-bond0.can0
wicked ifreload bond0.can0
