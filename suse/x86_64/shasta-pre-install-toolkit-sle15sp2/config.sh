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
# Install Cray Specific RPMs
#--------------------------------------
zypper \
  --no-gpg-checks \
  --plus-repo=http://car.dev.cray.com/artifactory/shasta-premium/MTL/sle15_sp2_ncn/x86_64/dev/master/ \
  --plus-repo=http://car.dev.cray.com/artifactory/shasta-premium/MTL/sle15_sp2_ncn/noarch/dev/master/ \
  --plus-repo=http://car.dev.cray.com/artifactory/shasta-premium/SPET/sle15_sp2_ncn/noarch/dev/master/ \
  in \
  -y \
  basecamp \
  metal-ipxe \
  metal-docs-ncn \
  nexus \
  shasta-instance-control

#======================================
# Cache docker images.
#--------------------------------------
podman pull sonatype/nexus
podman pull dtr.dev.cray.com/metal/cloud-basecamp
podman pull dtr.dev.cray.com/cray/cray-nexus-setup

#======================================
# Activate services
#--------------------------------------
suseInsertService apache2
suseInsertService conman
suseInsertService dnsmasq
suseInsertService sshd

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

#======================================
# Force root user to change password
# at first login.
#--------------------------------------
chage -d 0 root

#==========================================
# remove package docs
#------------------------------------------
rm -rf /usr/share/doc/packages/*
rm -rf /usr/share/doc/manual/*

# Goss is used during packer builds, installs, and continuously to check
# NCN health.
goss_version="0.3.13"
echo "Installing goss"
curl -L https://github.com/aelsabbahy/goss/releases/download/v${goss_version}/goss-linux-amd64 -o /usr/bin/goss
chmod a+x /usr/bin/goss
