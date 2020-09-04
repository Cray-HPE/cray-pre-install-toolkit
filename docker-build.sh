#!/bin/bash
#
# Jenkinsfile helper script.
# Builds OS Image and copies rpms to well-known folder
#
# Copyright 2020 Cray Inc.


save_build_dir () {
	if [[ -e /build && -e build_output ]]; then
		cp -a /build/* build_output/
	else
		Echo "Failed before /build and ./build_output were created!"
	fi
}

trap save_build_dir ERR

set -ex

DESC_DIR=suse/x86_64/sles15sp2

cd /base

# Clean the build directory if it exists, or 
# create it if it doesn't.
if [[ -e /build ]]; then
    rm -rf /build/*
else
    mkdir -p /build
fi

# Clean the build_output directory if it exists,
# or create it if it doesn't.
if [[ -e build_output ]]; then
    rm -rf build_output/*
else
    mkdir -p build_output
fi

# Build OS image tarball
time /usr/bin/kiwi-ng --type iso --debug system build --description $DESC_DIR --target-dir /build

# Copy build artifacts to external mounted directory
cp /build/*.iso /build/*.packages /build/*.verified ./build_output

exit 0
