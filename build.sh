#!/bin/bash
#
# Jenkinsfile helper script.
# Builds OS Image and copies rpms to well-known folder
#
# Copyright 2020 Cray Inc.

set -ex

DESC_DIR=suse/x86_64/suse-leap-15.1-JeOS

cd /base

# Build OS image tarball
time /usr/bin/kiwi-ng --type iso --debug system build --description $DESC_DIR --target-dir /build/output

ISO=$(basename /build/output/*.iso)
PACKAGES=$(basename /build/output/*.packages)
VERIFIED=$(basename /build/output/*.verified)

exit 0
