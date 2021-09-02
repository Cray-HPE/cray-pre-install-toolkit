#!/bin/bash

set -eu
if [ $# -lt 1 ]; then
cat << EOM >&2
  usage: csi-setup-hmn.sh CIDR|IP/MASQ VLAN_ID
  i.e.: csi-setup-hmn.sh 10.254.1.1/17 4
EOM
  exit 1
fi
cidr="$1"
addr="$(echo $cidr | cut -d '/' -f 1)"
mask="$(echo $cidr | cut -d '/' -f 2)"
vlan="$(echo $cidr | cut -d '/' -f 3)"
sed -i 's/^IPADDR=.*/IPADDR="'"${addr}"'\/'"${mask}"'"/g' /etc/sysconfig/network/ifcfg-bond0.hmn0
sed -i 's/^PREFIXLEN=.*/PREFIXLEN="'"${mask}"'"/g' /etc/sysconfig/network/ifcfg-bond0.hmn0
sed -i 's/^VLANID=.*/VLANID="'"${vlan:-4}"'"/g' /etc/sysconfig/network/ifcfg-bond0.hmn0
wicked ifreload bond0.hmn0