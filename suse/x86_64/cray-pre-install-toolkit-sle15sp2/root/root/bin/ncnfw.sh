#!/bin/bash

fw_home=http://pit/fw/river
${fw_home}/$filename

# Use the IPMI_PASSWORD if that's set.
password=${password:-${IPMI_PASSWORD}}

[ -z "$1" ] && {
    echo >&2 'Need target node name (DNS name)'
    exit 1
}
[ -z $username ] || [ -z $password ] && echo >&2 'Missing username or password; export username=root; export password=password'

curl -X POST -k -u $username:$password https://$1/redfish/v1/UpdateService/Actions/UpdateService.Simpleupdate/ -H Content-Type:application/json -d '{"TransferProtocol":"HTTP", "ImageURI":"'$image'"}'
echo "If you see success, check status with the following command."
watch "curl -sk -u $username:$password https://$1/redfish/v1/UpdateService | jq |grep -E 'State|Progress|Status'""
echo "curl -sk -u root:initial0 https://$1/redfish/v1/UpdateService |jq |grep -E 'State|Progress|Status'"

