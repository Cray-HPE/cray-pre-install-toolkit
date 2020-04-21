#!/bin/bash -ex
#
# Jenkinsfile helper script.
# Renames image file to include specific Cray version.
#
# Copyright 2019 Cray Inc. All Rights Reserved.

HASH=$(git log -n 1 --pretty=format:'%h')

for f in "$@"; do
    # IMG_VER and BUILD_TS set in Jenkinsfile
    new="${f/CRAY.VERSION.HERE/$IMG_VER-$BUILD_TS-g$HASH}"
    [[ "$f" != "$new" ]] && mv "$f" "$new"
done
