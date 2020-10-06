#!/bin/bash
WEB_ROOT=/var/www
initrd="$(ls -1tr $WEB_ROOT/ephemeral/data/*initrd*xz | head -n 1)"
kernel="$(ls -1tr $WEB_ROOT/ephemeral/data/*.kernel | head -n 1)"
k8s="$(ls -1tr $WEB_ROOT/ephemeral/data/k8s/*.squashfs | head -n 1)"
storage="$(ls -1tr $WEB_ROOT/ephemeral/data/ceph/*.squashfs | head -n 1)"

# FIXME: MTL-1204 Remove this hardcode when this script is ported into Shasta-Instance-Control.
ln -vnsf .${initrd///var\/www} initrd.img.xz
ln -vnsf .${kernel///var\/www} kernel
for ncn in $(grep -Eo 'ncn-[mw]\w+' /var/lib/misc/dnsmasq.leases | sort -u); do
    ln -vsnf .${k8s///var\/www} ${ncn}.squashfs
done
for ncn in $(grep -Eo 'ncn-s\w+' /var/lib/misc/dnsmasq.leases | sort -u); do
    ln -vsnf .${storage///var\/www} ${ncn}.squashfs
done

if ! [ $(pwd) = $WEB_ROOT ]; then
    mv ncn-* $WEB_ROOT
    mv kernel $WEB_ROOT
    mv initrd.img.xz $WEB_ROOT
fi
