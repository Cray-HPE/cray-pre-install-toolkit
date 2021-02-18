#!/bin/bash
# mfw: "metal firmware"

if [ $# -lt 1 ]; then
cat << EOM >&2
  usage: mfw <filename|pattern>
  i.e.: mfw A43
  i.e.: mfw A43_1.30_07_18_2020.signed.flash
EOM
  exit 1
fi

fw_home=http://pit/fw/river
username=${username:-admin}
password=${password:-password}

# FIXME: Remove '-k' for insecure.
curl -X POST -k -u $username:$password https://$1/redfish/v1/UpdateService/Actions/UpdateService.Simpleupdate/ -H Content-Type:application/json -d '{"TransferProtocol":"HTTP", "ImageURI":"'$image'"}'