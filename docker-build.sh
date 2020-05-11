#!/bin/bash
#
# Jenkinsfile helper script.
# Builds OS Image and copies rpms to well-known folder
#
# Copyright 2020 Cray Inc.

set -ex

DESC_DIR=suse/x86_64/cray-sles15sp1-JeOS

cd /base

# Clean the build directory if it exists, or 
# create it if it doesn't.
if [[ -e /build ]]; then
    rm -rf /build/*
else
    mkdir -p /build
fi

# Clean the build.out directory if it exists,
# or create it if it doesn't.
if [[ -e build.out ]]; then
    rm -rf build.out/*
else
    mkdir -p build.out
fi

# Build OS image tarball
time /usr/bin/kiwi-ng --type iso --debug system build --description $DESC_DIR --target-dir /build
# Copy image-root on failure.
[[ $? -ne 0 ]] && echo "Failed: kiwi-ng system build" && cp -a /build/* ./build.out/ && exit 1

# Copy build artifacts to external mounted directory
cp /build/*.iso /build/*.packages /build/*.verified ./build.out

exit 0
