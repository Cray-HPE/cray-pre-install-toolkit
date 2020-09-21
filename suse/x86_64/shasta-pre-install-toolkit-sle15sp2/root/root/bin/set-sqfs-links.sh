#!/bin/bash
WEB_ROOT=/var/www/
ln -snf "$(ls -1tr $WEB_ROOT/ephemeral/*initrd*xz | head -n 1)" "$WEB_ROOT/initrd.img.xz"
ln -snf "$(ls -1tr $WEB_ROOT/ephemeral/*.kernel | head -n 1)" "$WEB_ROOT/kernel"
ln -snf "$(ls -1tr $WEB_ROOT/ephemeral/k8s/*.squashfs | head -n 1)" "$WEB_ROOT/k8s-filesystem.squashfs"
ln -snf "$(ls -1tr $WEB_ROOT/ephemeral/ceph/*.squashfs | head -n 1)" "$WEB_ROOT/ceph-filesystem.squashfs"
ln -snf "$WEB_ROOT/ceph-filesystem.squashfs" "$WEB_ROOT/filesystem.squashfs"
test -e "$WEB_ROOT/initrd.img.xz" || echo No initrd
test -e "$WEB_ROOT/kernel" || echo No Kernel
test -e "$WEB_ROOT/filesystem.squashfs" || echo No SquashFS image found.
echo "By default this sets ceph to boot first, check ${WEB_ROOT} file listing."
