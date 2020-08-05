#!/bin/bash

set -eu
if [ $# -lt 2 ]; then
    echo >&2 "usage: sicfg-nic-lan1 CIDR|IP/MASQ GATEWAY"
    exit 1
fi
cidr="$1"
gateway="$2"
addr="$(echo $cidr | cut -d '/' -f 1)"
mask="$(echo $cidr | cut -d '/' -f 2)"
sed -i 's/^IPADDR=.*/IPADDR="'"${addr}"'\/'"${mask}"'"/g' /etc/sysconfig/network/ifcfg-lan1
sed -i 's/^PREFIXLEN=.*/PREFIXLEN="'"${mask}"'"/g' /etc/sysconfig/network/ifcfg-lan1
echo "default $gateway - -" >/etc/sysconfig/network/ifroute-lan1
wicked ifreload lan1