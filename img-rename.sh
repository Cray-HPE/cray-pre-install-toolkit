#!/bin/bash -ex
#
# Jenkinsfile helper script.
# Renames image file to include specific Cray version.
#
# Copyright 2019-2020 Cray Inc.

# Get x.y.z version from .version file
IMG_VER=$(cat .version)
# Get a timestamp for this build based on this rename operation
BUILD_TS=$(date -u '+%Y%m%d%H%M%S')
# Get HEAD commit ID for the branch used in build
HASH=$(git log -n 1 --pretty=format:'%h')

for f in "$@"; do
    new="${f/CRAY.VERSION.HERE/$IMG_VER-$BUILD_TS-g$HASH}"
    [[ "$f" != "$new" ]] && mv "$f" "$new"
done
