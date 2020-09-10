#!/bin/bash
WEB_ROOT=/var/basecamp/static/
ln -snf "$(ls -1tr $WEB_ROOT/ephemeral/*initrd*xz | head -n 1)" "$WEB_ROOT/initrd.img.xz"
ln -snf "$(ls -1tr $WEB_ROOT/ephemeral/*.kernel | head -n 1)" "$WEB_ROOT/kernel"
ln -snf "$(ls -1tr $WEB_ROOT/ephemeral/*.squashfs | head -n 1)" "$WEB_ROOT/filesystem.squashfs"
test -e "$WEB_ROOT/initrd.img.xz" || echo No initrd
test -e "$WEB_ROOT/kernel" || echo No Kernel
test -e "$WEB_ROOT/filesystem.squashfs" || echo No SquashFS image found.
