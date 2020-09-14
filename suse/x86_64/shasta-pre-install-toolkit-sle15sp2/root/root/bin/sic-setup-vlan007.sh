#!/bin/bash

set -eu
if [ $# -lt 1 ]; then
cat << EOM >&2
  usage: sic-setup-vlan007.sh CIDR|IP/MASQ
  i.e.: sic-setup-vlan007.sh 10.102.9.110/24 
EOM
  exit 1
fi
cidr="$1"
addr="$(echo $cidr | cut -d '/' -f 1)"
mask="$(echo $cidr | cut -d '/' -f 2)"
sed -i 's/^IPADDR=.*/IPADDR="'"${addr}"'\/'"${mask}"'"/g' /etc/sysconfig/network/ifcfg-vlan007
sed -i 's/^PREFIXLEN=.*/PREFIXLEN="'"${mask}"'"/g' /etc/sysconfig/network/ifcfg-vlan007
# FIXME: template this, use the automation key and replace the whole line.
printf '% -15s % -65s\n' "$addr" 'spit.can spit #${AUTOMATION}' >> /etc/hosts
wicked ifreload vlan007
