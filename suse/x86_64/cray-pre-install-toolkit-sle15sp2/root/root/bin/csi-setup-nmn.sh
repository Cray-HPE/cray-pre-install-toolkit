#!/bin/bash

set -eu
if [ $# -lt 1 ]; then
cat << EOM >&2
  usage: csi-setup-nmn.sh CIDR|IP/MASQ VLAN_ID
  i.e.: csi-setup-nmn.sh 10.252.1.1/17 2
EOM
  exit 1
fi
cidr="$1"
addr="$(echo $cidr | cut -d '/' -f 1)"
mask="$(echo $cidr | cut -d '/' -f 2)"
vlan="$(echo $cidr | cut -d '/' -f 3)"
sed -i 's/^IPADDR=.*/IPADDR="'"${addr}"'\/'"${mask}"'"/g' /etc/sysconfig/network/ifcfg-bond0.nmn0
sed -i 's/^PREFIXLEN=.*/PREFIXLEN="'"${mask}"'"/g' /etc/sysconfig/network/ifcfg-bond0.nmn0
sed -i 's/^VLANID=.*/VLANID="'"${vlan:-2}"'"/g' /etc/sysconfig/network/ifcfg-bond0.nmn0
wicked ifreload bond0.nmn0