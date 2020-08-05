#!/bin/bash
WEB_ROOT=/var/www
ln -snf "$(ls -1tr $WEB_ROOT/ephemeral/*initrd.xz*)" "$WEB_ROOT/initrd"
ln -snf "$(ls -1tr $WEB_ROOT/ephemeral/*vmlinuz*)" "$WEB_ROOT/vmlinuz"
ln -snf "$(ls -1tr $WEB_ROOT/ephemeral/*.squashfs)" "$WEB_ROOT/filesystem.squashfs"
test -e "$WEB_ROOT/initrd.xz" || echo No initrd
test -e "$WEB_ROOT/vmlinuz" || echo No Kernel
test -e "$WEB_ROOT/filesystem.squashfs" || echo No SquashFS image found.
