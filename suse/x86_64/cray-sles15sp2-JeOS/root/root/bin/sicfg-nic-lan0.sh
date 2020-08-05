#!/bin/bash

set -eu
if [ $# -lt 1 ]; then
    echo >&2 "usage: sicfg-nic-lan0 CIDR|IP/MASQ"
    exit 1
fi
cidr="$1"
addr="$(echo $cidr | cut -d '/' -f 1)"
mask="$(echo $cidr | cut -d '/' -f 2)"
sed -i 's/^IPADDR=.*/IPADDR="'"${addr}"'\/'"${mask}"'"/g' /etc/sysconfig/network/ifcfg-lan0
sed -i 's/^PREFIXLEN=.*/PREFIXLEN="'"${mask}"'"/g' /etc/sysconfig/network/ifcfg-lan0
printf '% -15s % -65s\n' "$addr" 'spit.local spit' >> /etc/hosts
wicked ifreload lan0