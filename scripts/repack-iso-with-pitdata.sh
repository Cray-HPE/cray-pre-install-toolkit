#!/usr/bin/env bash
# vim: et sw=4 ts=4 autoindent
#
# Copyright 2020 Hewlett Packard Enterprise Development LP
#
# Create a bootable ISO with PITDATA embedded into the image.
#
# Script takes an existing PIT ISO and a PITDATA directory and embeds
# the configs into a new ISO while ensuring the ISO remains bootable.
#
# This allows for booting directly to the new ISO using the BMC's virtual
# media capabilities so that there is no reliance on a physical USB drive
# being inserted into the machine

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
    ISO-FILE         Pathname or URL of LiveCD ISO file to write to the usb
                     flash drive.

    PITDATA-DIR      Directory where existing PITDATA configs are located. Directory will be embedded into
                     the new ISO

    OUTPUT-ISO-FILE  Location where the new ISO will be written to
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


info "ISO-FILE:        $iso_file"
info "PITDATA-DIR:     ${pitdata_dir}MB"
info "OUTPUT-ISO-FILE: $output_iso_file"

# check to ensure the ISO file exists
if [[ ! -r "$iso_file" ]]; then
    error "File ${iso_file} does not exist or is not readable."
    exit 1
fi

[[ ! command -v xorriso ]]; then
    error "xorriso does not exist or is not on path."
    exit 1
fi

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

# Pull isohdpfx from current iso
info "Extracting isohdfpx from $iso_file"
isohdpfx_tmp_file=$(mktemp  -p ${dir}/.cache)
dd if=$iso_file bs=512 count=1 of=$isohdpfx_tmp_file

info "Creating new efi bootable iso with xorriso"
xorriso -as mkisofs -isohybrid-mbr $isohdpfx_tmp_file \
  --boot-catalog-hide -b /boot/x86_64/loader/eltorito.img -no-emul-boot -boot-load-size 4 -boot-info-table \
  -eltorito-alt-boot -e boot/x86_64/efi -no-emul-boot -isohybrid-gpt-basdat \
  -volid 'CRAYLIVE' \
  -o $output_iso_file $iso_extracted_dir

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
rm $isohdpfx_tmp_file
rm -rf $iso_extracted_dir

printf "\n\nOnce booted link PITDATA to correct directory with \'ln -sf /run/initramfs/live/LiveOS/PITDATA /var/www/ephemeral\'"
