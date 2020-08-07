#!/bin/bash

if [ $# -lt 2 ]; then
    echo >&2 "usage: basecamp-init PIDFILE CIDFILE [CONTAINER [VOLUME]]"
    exit 1
fi

BASECAMP_PIDFILE="$1"
BASECAMP_CIDFILE="$2"
BASECAMP_CONTAINER_NAME="${3-basecamp}"
BASECAMP_CONTAINER_IMAGE="dtr.dev.cray.com/metal/mtl-${BASECAMP_CONTAINER_NAME}"
BASECAMP_VOLUME_NAME="${4:-${BASECAMP_CONTAINER_NAME}-configs}"

BASECAMP_VOLUME_MOUNT="/var/basecamp/configs:rw,exec"

command -v podman >/dev/null 2>&1 || { echo >&2 "${0##*/}: command not found: podman"; exit 1; }

set -x

# always ensure pid file is fresh
rm -f "$BASECAMP_PIDFILE"
mkdir -pv /var/basecamp/configs/

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
        --volume "${BASECAMP_VOLUME_NAME}:${BASECAMP_VOLUME_MOUNT}" \
        --name "$BASECAMP_CONTAINER_NAME" \
        "$BASECAMP_CONTAINER_IMAGE" || exit
    podman inspect "$BASECAMP_CONTAINER_NAME" || exit
fi
