#!/bin/bash
WEB_ROOT=/var/www
image=${1:-ceph}
ln -snf "$(ls -1tr $WEB_ROOT/ephemeral/data/*initrd*xz | head -n 1)" "$WEB_ROOT/initrd.img.xz"
ln -snf "$(ls -1tr $WEB_ROOT/ephemeral/data/*.kernel | head -n 1)" "$WEB_ROOT/kernel"
ln -snf "$(ls -1tr $WEB_ROOT/ephemeral/data/$image/*.squashfs | head -n 1)" "$WEB_ROOT/filesystem.squashfs"
ln -snf "$(ls -1tr $WEB_ROOT/ephemeral/data/k8s/*.squashfs | head -n 1)" "$WEB_ROOT/k8s-filesystem.squashfs"
ln -snf "$(ls -1tr $WEB_ROOT/ephemeral/data/ceph/*.squashfs | head -n 1)" "$WEB_ROOT/ceph-filesystem.squashfs"
if [[ -z $1 ]]; then
    echo "To set the active boot image, pass in any dir name in ${WEB_ROOT}/ephemeral/data."
    echo "By default this sets ceph to boot first, check ${WEB_ROOT} file listing."
fi
test -e "$WEB_ROOT/initrd.img.xz" || echo No initrd
test -e "$WEB_ROOT/kernel" || echo No Kernel
test -e "$WEB_ROOT/filesystem.squashfs" || echo No SquashFS image found.
