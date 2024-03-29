#!/bin/bash
#
# MIT License
#
# (C) Copyright 2020-2022 Hewlett Packard Enterprise Development LP
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
#

if [[ $# -eq 0 ]]; then
	WORKSPACE=$PWD
else
	WORKSPACE=$1
fi

DOCKER_IMAGE="artifactory.algol60.net/csm-docker/stable/builder-cray-pre-install-toolkit:1.2.1"
BUILD_OUTPUT=${WORKSPACE}/build_output

if [[ -z $PIT_SLUG ]]; then
  # Get x.y.z version from .version file
  export PIT_VERSION=$VERSION
  # Get a timestamp for this build based on this rename operation
  export PIT_TIMESTAMP=$(date -u '+%Y%m%d%H%M%S')
  export PIT_SLUG="${PIT_VERSION}-${PIT_TIMESTAMP}"
else
  export PIT_VERSION=$(echo $PIT_SLUG | cut -d '-' -f1)
  export PIT_TIMESTAMP=$(echo $PIT_SLUG | cut -d '-' -f2)
fi

export ARTIFACTORY_USER=$ARTIFACTORY_USER
export ARTIFACTORY_TOKEN=$ARTIFACTORY_TOKEN

# If the image already exists on the node,
# remove it. If the image is in use by a
# running container it will only be untagged.
# The untagged container will eventually be
# deleted by pruning. The test for count
# of lines from docker image ls has to account
# for the always present header line.
if [[ $(docker image ls ${DOCKER_IMAGE} | wc -l) -gt 1 ]]; then
	docker rmi -f ${DOCKER_IMAGE}
	[[ $? -ne 0 ]] && echo "Failed: docker rmi command" && exit 1
fi

# The output of a build will be stored in
# the container at /base/build_output. That
# translates into ${WORKSPACE}/build_output
# outside the container.
# Map /dev to /dev so loop devices will work
# the first time they are created after boot
docker run --rm -e PIT_VERSION -e PIT_TIMESTAMP -e TARGET_OS -e ARTIFACTORY_USER -e ARTIFACTORY_TOKEN -v ${WORKSPACE}:/base -v /dev:/dev --privileged --dns 172.30.84.40 --dns 172.31.84.40 ${DOCKER_IMAGE} bash /base/docker-build.sh
[[ $? -ne 0 ]] && echo "Failed: docker run command" && exit 1

# Chown the files created in docker so jenkins user can mv them
sudo chown -R $(whoami):$(whoami) build_output

# Rename the files to match Cray versioning
for f in $BUILD_OUTPUT/*; do
    new="${f/CRAY.VERSION.HERE/${PIT_SLUG}}"
    if [[ "$f" != "$new" ]]; then
        mv "$f" "$new"
	[[ $? -ne 0 ]] && echo "Failed: rename of image $f to $new" && exit 1
    fi
done

exit 0
