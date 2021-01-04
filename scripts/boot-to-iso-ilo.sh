#!/usr/bin/env bash
# vim: et sw=4 ts=4 autoindent
#
# Copyright 2020 Hewlett Packard Enterprise Development LP
#
# Reboots an ILO machine from a virtual ISO and connect to terminal
#
# Script takes an existing ISO, like one created from `repack-iso-with-pitdata.sh` and a BNC endpint
# It will with prompt for the BMC password, connect to the BMC, mount the ISO, reboot the machine, and
# drop in a ipmitool terminal

set -e

name=$(basename $0)
dir=$(dirname $0)

# Initial empty values for iso url, bmc ip
iso_url=""
bmc_host=""


usage () {
    cat << EOF
Usage $name ISO-URL BMC-HOST

where:
    ISO-FILE      An Http(s) url where the ISO can be accessed from the BMC

    BMC-HOST      A DNS hostname or IP address where the BNC managment can be reached

EOF
}

error () {
    mesg ERROR $@
}

warning () {
    mesg WARNING $@
}

info () {
    mesg INFO $@
}

mesg () {
    LEVEL=$1
    shift 1
    echo "$LEVEL: $@"
}


# Process cmdline arguments
[[ $# < 2 ]] && usage && exit 1
[[ $# > 2 ]] && usage && exit 1
iso_url=$1
shift 1
bmc_host=$1
shift 1

# Prompt for bmc password
# Read Password
echo -n BMC Password:
read -s bmc_password
echo

info "ISO-URL:   $iso_url"
info "BMC-HOST:  $bmc_host"

info "Checking if ISO-URL is reachable"
[[ ! curl --head --fail "$iso_url" ]]; then
    error "$iso_url was not reachable via curl"
    exit 1
fi

[[ ! command -v sshpass ]]; then
    error "sshpass does not exist or is not on path."
    exit 1
fi

# Issue bmc commands via ssh one at a time
bmc_commands=(
    "vm cdrom get"
    "vm cdrom eject"
    "vm cdrom insert $iso_url"
    "vm cdrom set connect"
    "vm cdrom set boot_once"
    "power reset"
)

for command in "${bmc_commands[@]}"; do
    printf "\n\nRunning command $command\n"
    sshpass -p $bmc_password ssh root@$bmc_host "$command"
done


# Connect to terminal
echo "Conneting to $bmc_host with ipmitool"
ipmitool -I lanplus -U root -P $bmc_password -H $bmc_host sol activate
