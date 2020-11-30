#!/bin/bash
# Copyright 2020 HPED LP
set -e

usage() {
  # Generates a usage line
  # Any line startng with with a #/ will show up in the usage line
  grep '^#/' "$0" | cut -c4-
}

# Show usage when --help is passed
expr "$*" : ".*--help" > /dev/null && usage && exit 0

UPSTREAM_NTP_SERVER=$(curl -s http://localhost:8888/meta-data | jq | awk -F '"' '/upstream_ntp_server/ {print $4}' || echo -n '' )
NTP_PEERS=$(curl -s http://localhost:8888/meta-data | jq | awk -F '"' '/ntp_peers/ {print $4}' || echo -n '' )
NTP_LOCAL_NETS=$(curl -s http://localhost:8888/meta-data | jq | awk -F '"' '/ntp_local_nets/ {print $4}' || echo -n '' )
CHRONY_CONF=/etc/chrony.d/cray.conf


create_chrony_config() {
  # clear the file first, making it if needed
  true >"$CHRONY_CONF"

  if [[ -z $UPSTREAM_NTP_SERVER ]]; then
    :
  else
    echo "server $UPSTREAM_NTP_SERVER iburst maxsources 3" >>"$CHRONY_CONF"
  fi

  for net in ${NTP_LOCAL_NETS}
  do
     echo "allow $net" >>"$CHRONY_CONF"
  done

  echo "local stratum 3 orphan" >>"$CHRONY_CONF"
  echo "log measurements statistics tracking" >>"$CHRONY_CONF"
  echo "logchange 1.0" >>"$CHRONY_CONF"

  for n in $NTP_PEERS
  do
    if [[ "$HOSTNAME" != "$n" ]]; then
      echo "peer $n minpoll -2 maxpoll 9 iburst" >>"$CHRONY_CONF"
    fi
  done
}

#/ Usage: set-ntp-config.sh [--help]
#/                          [-u|--upstream-site-ntp] HOST_OR_IP
#/
#/    Configures NTP on the NCNs
#/

UNKNOWN=()
while [[ $# -gt 0 ]]
do
  case "$1" in
    -u|--upstream-site-ntp)
      UPSTREAM_NTP_SERVER="$2"
      shift
      shift
      ;;
    *) # unknown option
      UNKNOWN+=("$1")
      shift
      ;;
  esac
done

set -- "${UNKNOWN[@]}" # restore positional parameters

create_chrony_config
systemctl enable chronyd
systemctl restart chronyd
