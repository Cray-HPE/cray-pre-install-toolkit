#!/bin/bash
WEB_ROOT=/var/www
ln -snf "$(ls -1tr $WEB_ROOT/ephemeral/*initrd*)" "$WEB_ROOT/initrd"
ln -snf "$(ls -1tr $WEB_ROOT/ephemeral/*vmlinuz*)" "$WEB_ROOT/linux"
ln -snf "$(ls -1tr $WEB_ROOT/ephemeral/*.squashfs*)" "$WEB_ROOT/ncn-image.squashfs"
test -e "$WEB_ROOT/initrd"
test -e "$WEB_ROOT/linux" || echo Noo Kernel
test -e "$WEB_ROOT/ncn-image.squashfs" || echo No SquashFS image found.
