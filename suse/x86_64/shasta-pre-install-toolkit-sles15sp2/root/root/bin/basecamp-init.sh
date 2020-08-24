#!/bin/bash

set -x
if [ $# -lt 2 ]; then
    echo >&2 "usage: basecamp-init PIDFILE CIDFILE [CONTAINER [VOLUME]]"
    exit 1
fi

BASECAMP_PIDFILE="$1"
BASECAMP_CIDFILE="$2"
BASECAMP_CONTAINER_NAME="${3-basecamp}"
BASECAMP_CONTAINER_IMAGE="dtr.dev.cray.com/metal/cloud-${BASECAMP_CONTAINER_NAME}"
BASECAMP_VOLUME_NAME="${4:-${BASECAMP_CONTAINER_NAME}-configs}"

BASECAMP_VOLUME_MOUNT_CONFIG="/var/www/basecamp/configs:/app/configs:rw,exec"
BASECAMP_VOLUME_MOUNT_STATIC="/var/www/basecamp/static:/app/static:rw,exec"

command -v podman >/dev/null 2>&1 || { echo >&2 "${0##*/}: command not found: podman"; exit 1; }


# always ensure pid file is fresh
rm -f "$BASECAMP_PIDFILE"
mkdir -pv "$(echo ${BASECAMP_VOLUME_MOUNT_CONFIG} | cut -f 1 -d :)"
mkdir -pv "$(echo ${BASECAMP_VOLUME_MOUNT_CONFIG} | cut -f 1 -d :)"
test -e "$(echo ${BASECAMP_VOLUME_MOUNT_CONFIG} | cut -f 1 -d :)/data.json" ||\
cat << EOF > "$(echo ${BASECAMP_VOLUME_MOUNT_CONFIG} | cut -f 1 -d :)/data.json"
{
  [
    // "mac": {metadata...}
  ]
}
EOF
# Set up a mutable, default file. Users reading this, can edit this or edit the
# actual created file. Editing here is persistent on restart.
test -e "$(echo ${BASECAMP_VOLUME_MOUNT_CONFIG} | cut -f 1 -d :)/server.yaml" ||\
cat << EOF > "$(echo ${BASECAMP_VOLUME_MOUNT_CONFIG} | cut -f 1 -d :)/server.yaml"
# Basecamp Configuration
bind: ":8888"
local-mode: true
local-data: "./config/data.json"
serve-static: true
static-dir: "./static/"
EOF

mkdir -pv "$(echo ${BASECAMP_VOLUME_MOUNT_STATIC} | cut -f 1 -d :)"
# Create basecamp container
if ! podman inspect "$BASECAMP_CONTAINER_NAME" ; then
    rm -f "$BASECAMP_CIDFILE" || exit
    podman pull "$BASECAMP_CONTAINER_IMAGE" || exit
    podman create \
        --conmon-pidfile "$BASECAMP_PIDFILE" \
        --cidfile "$BASECAMP_CIDFILE" \
        --cgroups=no-conmon \
        -d \
        --net host \
        --volume "$BASECAMP_VOLUME_MOUNT_STATIC" \
        --name "$BASECAMP_CONTAINER_NAME" \
        --env GIN_MODE="${GIN_MODOE:-release}" \
        "$BASECAMP_CONTAINER_IMAGE" || exit
    podman inspect "$BASECAMP_CONTAINER_NAME" || exit
fi
