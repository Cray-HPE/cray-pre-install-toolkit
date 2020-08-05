#!/bin/bash

set -eu
if [ $# -lt 1 ]; then
    echo >&2 "usage: sicfg-nic-vlan004 CIDR|IP/MASQ"
    exit 1
fi
cidr="$1"
addr="$(echo $cidr | cut -d '/' -f 1)"
mask="$(echo $cidr | cut -d '/' -f 2)"
sed -i 's/^IPADDR=.*/IPADDR="'"${addr}"'\/'"${mask}"'"/g' /etc/sysconfig/network/ifcfg-vlan004
sed -i 's/^PREFIXLEN=.*/PREFIXLEN="'"${mask}"'"/g' /etc/sysconfig/network/ifcfg-vlan004
wicked ifreload vlan004