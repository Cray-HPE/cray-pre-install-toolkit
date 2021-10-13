#!/usr/bin/env bash

if [[ $# -eq 0 ]]; then
	WORKSPACE=$PWD
else
	WORKSPACE=$1
fi

DOCKER_IMAGE="arti.dev.cray.com/csm-docker-master-local/build-cray-pre-install-toolkit:latest"
BUILD_OUTPUT=${WORKSPACE}/build_output

if [[ -z $PIT_SLUG ]]; then
  # Get x.y.z version from .version file
  export PIT_VERSION=$(cat .version)
  # Get a timestamp for this build based on this rename operation
  export PIT_TIMESTAMP=$(date -u '+%Y%m%d%H%M%S')
  # Get HEAD commit ID for the branch used in build
  export PIT_HASH=$(git log -n 1 --pretty=format:'%h')
  export PIT_SLUG="${PIT_VERSION}-${PIT_TIMESTAMP}-g${PIT_HASH}"
else
  export PIT_VERSION=$(echo $PIT_SLUG | cut -d '-' -f1)
  export PIT_TIMESTAMP=$(echo $PIT_SLUG | cut -d '-' -f2)
  export PIT_HASH=$(echo $PIT_SLUG | cut -d '-' -f3)
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
docker run --rm -e PIT_VERSION -e PIT_TIMESTAMP -e PIT_HASH -e ARTIFACTORY_USER -e ARTIFACTORY_TOKEN -v ${WORKSPACE}:/base -v /dev:/dev --privileged --dns 172.30.84.40 --dns 172.31.84.40 ${DOCKER_IMAGE} bash /base/docker-build.sh
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
