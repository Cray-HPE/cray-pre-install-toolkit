#!/bin/bash
WEB_ROOT=/var/www

# Finds latest of each artifact regardless of subdirectory.
k8s_initrd="$(find ${WEB_ROOT}/ephemeral/data/k8s -name *initrd* -printf '%T@ %p\n' | sort -n | tail -1 |  cut -f2- -d" ")"
k8s_kernel="$(find ${WEB_ROOT}/ephemeral/data/k8s -name *.kernel -printf '%T@ %p\n' | sort -n | tail -1 |  cut -f2- -d" ")"
k8s_squashfs="$(find ${WEB_ROOT}/ephemeral/data/k8s -name *.squashfs -printf '%T@ %p\n' | sort -n | tail -1 |  cut -f2- -d" ")"
ceph_initrd="$(find ${WEB_ROOT}/ephemeral/data/ceph -name *initrd* -printf '%T@ %p\n' | sort -n | tail -1 |  cut -f2- -d" ")"
ceph_kernel="$(find ${WEB_ROOT}/ephemeral/data/ceph -name *.kernel -printf '%T@ %p\n' | sort -n | tail -1 |  cut -f2- -d" ")"
ceph_squashfs="$(find ${WEB_ROOT}/ephemeral/data/ceph -name *.squashfs -printf '%T@ %p\n' | sort -n | tail -1 |  cut -f2- -d" ")"

# RULE! The kernels MUST match; the initrds may be different.
if [[ "$(basename ${k8s_kernel} | cut -d '-' -f1,2)" != "$(basename ${ceph_kernel} | cut -d '-' -f1,2)" ]]; then
    echo 'Mismatching kernels! The discovered artifacts will deploy an undesirable stack.' >&2
fi

echo "Making boot directories for nodes with BMCs that have leases in /var/lib/dnsmasq.d/leases"
echo "Nodes without boot directories will still boot the non-destructive iPXE binary."
for ncn in $(grep -Eo 'ncn-[mw]\w+' /var/lib/misc/dnsmasq.leases | sort -u); do
    mkdir -pv ${ncn} && pushd ${ncn}
    cp -pv /var/www/boot/script.ipxe .
    ln -vsnf ..${k8s_kernel///var\/www} kernel
    ln -vsnf ..${k8s_initrd///var\/www} initrd.img.xz
    ln -vsnf ..${k8s_squashfs///var\/www} filesystem.squashfs
    popd
done
for ncn in $(grep -Eo 'ncn-s\w+' /var/lib/misc/dnsmasq.leases | sort -u); do
    mkdir -pv ${ncn} && pushd ${ncn}
    cp -pv /var/www/boot/script.ipxe .
    ln -vsnf ..${ceph_kernel///var\/www} kernel
    ln -vsnf ..${ceph_initrd///var\/www} initrd.img.xz
    ln -vsnf ..${ceph_squashfs///var\/www} filesystem.squashfs
    popd
done

if ! [ $(pwd) = $WEB_ROOT ]; then
    rsync -rltDv --remove-source-files ncn-* $WEB_ROOT && rmdir ncn-*
fi
