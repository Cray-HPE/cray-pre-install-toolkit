#!/bin/bash
rDNS_FQDN=$(nslookup $addr - $(tail -n 1 /etc/resolv.conf | awk '{print $NF}') | awk '{print $NF}')
rDNS=$(echo $rDNS_FQDN | cut -d '.' -f1)
hostnamectl set-hostname ${rDNS}-pit
