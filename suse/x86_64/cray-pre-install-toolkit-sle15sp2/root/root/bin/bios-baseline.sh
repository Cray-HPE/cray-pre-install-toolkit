#!/bin/bash

set -u

bmc_username=${USERNAME:-$(whoami)}
if [[ $(hostname) == *-pit ]]; then
    host_bmc="$(hostname | cut -d '-' -f2,3)-mgmt"
else
    host_bmc="$(hostname)-mgmt"
fi
LOG_DIR=/var/log/metal/
mkdir -pv $LOG_DIR

# Lay of the Land; rules to abide by for reusable code, and easy identification of problems from new eyeballs.
# - For anything vendor related, use a common acronym (e.g. GigaByte=gb Hewlett Packard Enterprise=hpe)
# - do not add "big" (functions longer than 25 lines, give or take a reasonably, contextually relevant few couple of lines)


function check_compatibility() {
    local vendor=${1:-''}
    case $vendor in
        *GIGABYTE*)
            :
            ;;
        *Marvell*|HP|HPE)
            ilo_config
            ;;
        *'Intel'*'Corporation'*)
            echo :
            ;;
        *)
            :
            ;;
    esac
}


# die.. (quit and write a message into standard error).
function die(){
    [ -n "$1" ] && echo >&2 "$1" && exit 1
}

# Use IPMI_PASSWORD to align with ipmitools usage of the same environment variable as described in the Shasta documentation.
bmc_password=${IPMI_PASSWORD:-''}
[ -z "$bmc_password" ] && die 'Need IPMI_PASSWORD exported to the environment.'

function ilo_config() {
    check_compatibility hpe || die -
    (
        # Attempt a network boot only once on every interface connected to the deployment network.
        echo 'Setting "NetworkBootRetry=Disabled" ... '; ilorest set "NetworkBootRetry=Disabled" --selector=Bios. --commit

        # Attempt a network boot only once on every interface connected to the deployment network.
        echo 'Setting "HttpSupport=Disabled" ... '; ilorest set "HttpSupport=Disabled" --selector=Bios. --commit

        # Disable unused features; speed the boot process up, and remove unknown unknowns.
        echo 'Setting "iSCSISoftwareInitiator=Disabled" ... '; ilorest set "iSCSISoftwareInitiator=Disabled" --selector=Bios. --commit

        # Enable deterministic success/failure by assuring an end state is met; do not loop through entire BIOS or any subset.
        echo 'Setting "BootOrderPolicy=AttemptOnce" ... '; ilorest set "BootOrderPolicy=AttemptOnce" --selector=Bios. --commit

        # IPv4 is supported for both HTTP and PXE network boots, IPv6 is pending. See Cray System Management for a time-table.
        echo 'Setting "PrebootNetworkEnvPolicy=IPv4 ... '; ilorest set "PrebootNetworkEnvPolicy=IPv4" --selector=Bios. --commit

        # Ensure nothing is queued as far as changes/deltas go, and reboot to ensure all deltas/changes are picked up.
        ilorest pending
    ) 2>&1 >$LOG_DIR/${ncn_bmc}.log
}

function run_ilo() {
    # This only runs on HPE hardware.
    local vendor='hpe'
    local hosts_file=/etc/dnsmasq.d/statics.conf
    echo "This will ignore the host this was ran on [$host_bmc]"
    [ -f $hosts_file ] || hosts_file=/etc/hosts
    for ncn_bmc in $(grep -oP 'ncn-\w\d+-mgmt' $hosts_file | sort -u | grep -v ncn-m001-mgmt); do
        echo; echo "${ncn_bmc} ================================"

        check_compatibility $vendor || die "$ncn_bmc is not of H[ewlett]P[ackard]E[nterprise] origin and will not have an iLO configured."

        ilorest login ${ncn_bmc} -u ${bmc_username} -p ${bmc_password}

        ilo_config

        date && ilorest logout
    done
    echo "Applying settings to localhost [$host_bmc]"
    ilorest login 127.0.0.1 -u ${bmc_username} -p ${bmc_password}
    ilo_config
    date
    ilorest logout
}

run_ilo