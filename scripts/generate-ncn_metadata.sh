#!/usr/bin/env bash

if [ -z ${BOOTSTRAP_MAC_NAME+x} ]; then
  bootstrap_mac_name="em1"
else
  bootstrap_mac_name="$BOOTSTRAP_MAC_NAME"
fi

if [ -z ${BOND_MAC_NAME+x} ]; then
  bond_mac_name="bond0"
else
  bond_mac_name="$BOND_MAC_NAME"
fi

if [ -z "$IPMI_PASSWORD" ]; then
  echo >&2 'Need to export IPMI_PASSWORD for BMC access'
  echo >&2 '(optionally: export username, otherwise $(whoami) [current user] is used)'
  exit 1
fi
username=${username:-$(whoami)}

ncn_regex="ncn-[s|m|w]0*([0-9]+)*"

storage_xnames=$(cray hsm state components list --role Management --subrole Storage --format=json |
jq -r '.Components[] | .ID' | sort)
master_xnames=$(cray hsm state components list --role Management --subrole Master --format=json |
jq -r '.Components[] | .ID' | sort)
worker_xnames=$(cray hsm state components list --role Management --subrole Worker --format=json |
jq -r '.Components[] | .ID' | sort)

for xname in $storage_xnames
do
  sls_alias=$(curl -s -k -H "Authorization: Bearer ${TOKEN}" "https://api_gw_service.local/apis/sls/v1/hardware/$xname" | jq -r '.ExtraProperties.Aliases | .[] | .')
  if [[ $sls_alias =~ $ncn_regex ]]
  then
    index="${BASH_REMATCH[1]}"

    alias_name="Storage$index"
  fi

  bmc_mac=$(ipmitool -I lanplus -U $username -P $IPMI_PASSWORD -H ${xname%n0} lan print |
  grep "MAC Address" | rev | cut -d' ' -f1 | rev)
  bootstrap_mac=$(ssh $xname cat /sys/class/net/"$bootstrap_mac_name"/address)
  bond_mac=$(ssh $xname cat /sys/class/net/"$bond_mac_name"/address)

  echo "$xname,Management,$alias_name,$bmc_mac,$bootstrap_mac,$bond_mac"
done

for xname in $master_xnames
do
  sls_alias=$(curl -s -k -H "Authorization: Bearer ${TOKEN}" "https://api_gw_service.local/apis/sls/v1/hardware/$xname" | jq -r '.ExtraProperties.Aliases | .[] | .')
  if [[ $sls_alias =~ $ncn_regex ]]
  then
    index="${BASH_REMATCH[1]}"

    alias_name="Master$index"
  fi

  bmc_mac=$(ipmitool -I lanplus -U $username -P $IPMI_PASSWORD -H ${xname%n0} lan print |
  grep "MAC Address" | rev | cut -d' ' -f1 | rev)
  bootstrap_mac=$(ssh $xname cat /sys/class/net/"$bootstrap_mac_name"/address)
  bond_mac=$(ssh $xname cat /sys/class/net/"$bond_mac_name"/address)

  echo "$xname,Management,$alias_name,$bmc_mac,$bootstrap_mac,$bond_mac"

  (( COUNTER+=1 ))
done

for xname in $worker_xnames
do
  sls_alias=$(curl -s -k -H "Authorization: Bearer ${TOKEN}" "https://api_gw_service.local/apis/sls/v1/hardware/$xname" | jq -r '.ExtraProperties.Aliases | .[] | .')
  if [[ $sls_alias =~ $ncn_regex ]]
  then
    index="${BASH_REMATCH[1]}"

    alias_name="Worker$index"
  fi

  bmc_mac=$(ipmitool -I lanplus -U "$USERNAME" -P "$PASSWORD" -H "${xname%n0}" lan print |
  grep "MAC Address" | rev | cut -d' ' -f1 | rev)
  bootstrap_mac=$(ssh $xname cat /sys/class/net/"$bootstrap_mac_name"/address)
  bond_mac=$(ssh $xname cat /sys/class/net/"$bond_mac_name"/address)

  echo "$xname,Management,$alias_name,$bmc_mac,$bootstrap_mac,$bond_mac"

  (( COUNTER+=1 ))
done
