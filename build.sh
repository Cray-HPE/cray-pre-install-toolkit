#!/usr/bin/env bash

if [[ $# -eq 0 ]]; then
	WORKSPACE=$PWD
else
	WORKSPACE=$1
fi

DOCKER_IMAGE="dtr.dev.cray.com:443/cray/cray-preinstall-toolkit-builder:latest"

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
docker run -v ${WORKSPACE}:/base --privileged --dns 172.30.84.40 --dns 172.31.84.40 ${DOCKER_IMAGE} bash /base/docker-build.sh
[[ $? -ne 0 ]] && echo "Failed: docker run command" && exit 1

# Rename the files to match Cray versioning
./img-rename.sh build_output/*
[[ $? -ne 0 ]] && echo "Failed: img-rename.sh" && exit 1


exit 0
