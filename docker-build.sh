#!/bin/bash
#
# Jenkinsfile helper script.
# Builds OS Image and copies rpms to well-known folder
#
# Copyright 2020 Cray Inc.


save_build_dir () {
	echo "Build failure detected, copying build root from container to build_output."
	if [[ -e /build && -e build_output ]]; then
		cp -a /build/* build_output/
	else
		echo "Failed before /build and ./build_output were created!"
	fi
}

trap save_build_dir ERR

set -ex
# If TARGET_OS is defined, it's likely from automation and needs the underscores striped.
if [[ -n $TARGET_OS ]]; then
  TARGET_OS="$(echo $TARGET_OS | tr -d '-')"
fi
DESC_DIR=suse/${ARCH:-x86_64}/cray-pre-install-toolkit-${TARGET_OS}
RELEASE_FILE=$DESC_DIR/root/etc/pit-release

cd /base

envsubst < ${DESC_DIR}/config.template.xml > ${DESC_DIR}/config.xml

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

# Write the pre-install-toolkit version file for build into root overlay
cat << EOF > "$RELEASE_FILE"
VERSION=$PIT_VERSION
TIMESTAMP=$PIT_TIMESTAMP
EOF


# Build OS image tarball
zypper --non-interactive in -y wget
wget https://arti.dev.cray.com/artifactory/dst-misc-stable-local/SigningKeys/HPE-SHASTA-RPM-PROD.asc
time /usr/bin/kiwi-ng --profile=PITISO --type iso --debug system build --description $DESC_DIR --target-dir /build --signing-key HPE-SHASTA-RPM-PROD.asc

# Delete the pre-install-toolkit version file for build from root overlay
/bin/rm -f $RELEASE_FILE

# Copy build artifacts to external mounted directory
cp /build/*.iso /build/*.packages /build/*.verified ./build_output

exit 0
