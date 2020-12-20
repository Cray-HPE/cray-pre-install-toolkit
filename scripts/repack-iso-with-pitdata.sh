#!/usr/bin/env bash
# vim: et sw=4 ts=4 autoindent
#
# Copyright 2020 Hewlett Packard Enterprise Development LP
#
# Create a bootable pre-install-toolkit LiveCD USB drive.
#
# TODO DESCRIPTION

set -e

name=$(basename $0)
dir=$(dirname $0)

# Initial empty values for usb device and iso file
iso_file=""
pitdata_dir=""
output_iso_file=""


usage () {
    cat << EOF
Usage $name ISO-FILE PITDATA-DIR OUTPUT-ISO-FILE

where:
    TODO
EOF
}

error () {
    mesg ERROR $@
}

warning () {
    mesg WARNING $@
}

info () {
    mesg INFO $@
}

mesg () {
    LEVEL=$1
    shift 1
    echo "$LEVEL: $@"
}


# Process cmdline arguments
[[ $# < 3 ]] && usage && exit 1
[[ $# > 4 ]] && usage && exit 1
iso_file=$1
shift 1
pitdata_dir=$1
shift 1
output_iso_file=$1
shift 1


info "ISO-FILE:   $iso_file"
info "PITDATA-DIR:   ${pitdata_dir}MB"
info "OUTPUT-ISO-FILE:   $output_iso_file"

# check to ensure the ISO file exists
if [[ ! -r "$iso_file" ]]; then
    error "File ${iso_file} does not exist or is not readable."
    exit 1
fi

# TODO check that pitdata-dir is a directory

# TODO check that mksquashfs, mkisofs, and tagmedia/checkmedia is installed

# Create a cache directory to unpack in
mkdir -p ${dir}/.cache
iso_mount_dir=$(mktemp -d -p ${dir}/.cache)

info "Mounting iso to $iso_mount_dir"
mount $iso_file $iso_mount_dir

# Extracting iso contents
iso_extracted_dir=$(mktemp -d -p ${dir}/.cache)
info "Extracting iso to $iso_extracted_dir"
cp -r ${iso_mount_dir}/. ${iso_extracted_dir}

info "Cleaning up mount"
umount $iso_mount_dir
rm -rf $iso_mount_dir

# Move the pitdata_dir inside the iso folder
info "Copying $pitdata_dir to ${iso_extracted_dir}/LiveOS/PITDATA"
cp -R $pitdata_dir ${iso_extracted_dir}/LiveOS/PITDATA

# Create the new iso
info "Creating iso at $iso_extracted_dir with mkisofs"
mkisofs -o $output_iso_file \
  -b boot/x86_64/loader/eltorito.img -no-emul-boot -boot-load-size 4 -boot-info-table \
  -l -J -R -V "CRAYLIVE" $iso_extracted_dir

info "Adding digest with tagmedia"
if ! command -v tagmedia &> /dev/null
then
  warning "tagmedia could not be found run manually or in a container with tagmedia to fix"
  warning "tagmedia --digest sha256 --pad 150 $iso_extracted_dir"
else
  tagmedia --digest sha256 --pad 150 $output_iso_file
  checkmedia $output_iso_file
fi

# Cleanup
rm -rf $iso_extracted_dir

printf "\n\nOnce booted link PITDATA to correct directory with \'ln -sf /run/initramfs/live/LiveOS/PITDATA /var/www/ephemeral\'"
