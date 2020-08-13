#!/bin/bash

set -eu
if [ $# -lt 3 ]; then
cat << EOM >&2
    usage: sicfg-nic-lan0.sh CIDR|IP/MASQ FIRST_BOND_MEMBER SECOND_BOND_MEMBER
    i.e.: sicfg-nic-lan0.sh 10.1.1.1/16 p801p1 p801p2
EOM
  exit 1
fi
cidr="$1"
addr="$(echo $cidr | cut -d '/' -f 1)"
mask="$(echo $cidr | cut -d '/' -f 2)"
dev1="$2"
dev2="$3"
sed -i 's/^IPADDR=.*/IPADDR="'"${addr}"'\/'"${mask}"'"/g' /etc/sysconfig/network/ifcfg-lan0
sed -i 's/^PREFIXLEN=.*/PREFIXLEN="'"${mask}"'"/g' /etc/sysconfig/network/ifcfg-lan0
sed -i 's/^BONDING_SLAVE0=.*/BONDING_SLAVE0="'"${dev1}"'"/g' /etc/sysconfig/network/ifcfg-lan0
sed -i 's/^BONDING_SLAVE1=.*/BONDING_SLAVE1="'"${dev2}"'"/g' /etc/sysconfig/network/ifcfg-lan0
# FIXME: template this, use the automation key and replace the whole line.
printf '% -15s % -65s\n' "$addr" 'spit.local spit #${AUTOMATION}' >> /etc/hosts
wicked ifreload lan0