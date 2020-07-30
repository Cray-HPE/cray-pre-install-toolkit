#!/bin/bash
#================
# FILE          : config.sh
#----------------
# PROJECT       : OpenSuSE KIWI Image System
# COPYRIGHT     : (c) 2006 SUSE LINUX Products GmbH. All rights reserved
#               :
# AUTHOR        : Marcus Schaefer <ms@suse.de>
#               :
# BELONGS TO    : Operating System images
#               :
# DESCRIPTION   : configuration script for SUSE based
#               : operating systems
#               :
#               :
# STATUS        : BETA
#----------------
#======================================
# Functions...
#--------------------------------------
test -f /.kconfig && . /.kconfig
test -f /.profile && . /.profile

#======================================
# Greeting...
#--------------------------------------
echo "Configure image: [$kiwi_iname]..."

#======================================
# Setup baseproduct link
#--------------------------------------
suseSetupProduct

#======================================
# Activate services
#--------------------------------------
suseInsertService sshd
suseInsertService dhcpd
suseInsertService tftp.socket
suseInsertService apache2

#======================================
# Setup default target, multi-user
#--------------------------------------
baseSetRunlevel 3

#======================================
# Purge zypper repos, unused for shasta
#--------------------------------------
zypper --verbose clean --all
rm -r /etc/zypp/repos.d/*
cp /dev/null /var/log/zypper.log

#======================================
# Set hostname to cray-livecd
#--------------------------------------
echo "cray-livecd" > /etc/hostname

#======================================
# Add ll alias to profile
#--------------------------------------
echo "alias ll='ls -l --color'" >> /root/.bashrc

#==========================================
# Ensure tftp.socket is enabled
# FIXME: suseInsertService is not enabling.
#------------------------------------------
systemctl enable tftp.socket

#==========================================
# remove package docs
#------------------------------------------
rm -rf /usr/share/doc/packages/*
rm -rf /usr/share/doc/manual/*

#==========================================
# setup iPXE
#------------------------------------------
git clone git://git.ipxe.org/ipxe.git
pushd ipxe/src
cat > chainload.ipxe << EOF
#!ipxe
dhcp
chain http://cray-livecd.local/script.ipxe
EOF
make bin-x86_64-efi/ipxe.efi EMBED=chainload.ipxe
cp -pv bin-x86_64-efi/ipxe.efi /var/tftpboot/
popd
