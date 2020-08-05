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
suseInsertService dnsmasq
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
# Set hostname to spit
#--------------------------------------
echo "spit" > /etc/hostname

#======================================
# Add ll alias to profile
#--------------------------------------
echo "alias ll='ls -l --color'" >> /root/.bashrc

#==========================================
# setup iPXE
#------------------------------------------
git clone git://git.ipxe.org/ipxe.git
pushd ipxe/src
cat > chainload.ipxe << EOF
#!ipxe
dhcp
chain http://spit/script.ipxe
EOF
# Compile ipxe and embed our script.
make bin-x86_64-efi/ipxe.efi EMBED=chainload.ipxe
mkdir /var/tftpboot/
cp -pv bin-x86_64-efi/ipxe.efi /var/tftpboot/
chown dnsmasq:tftp /var/tftpboot
popd
# Leave the ipxe clone incase someone wants to recompile with same source.

#==========================================
# remove package docs
#------------------------------------------
rm -rf /usr/share/doc/packages/*
rm -rf /usr/share/doc/manual/*
