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
  --plus-repo=http://car.dev.cray.com/artifactory/shasta-premium/SPET/sle15_sp2_ncn/x86_64/dev/master/ \
  in \
  -y \
  cray-metal-basecamp \
  cray-metal-ipxe \
  cray-metal-nexus

#======================================
# Activate services
#--------------------------------------
suseInsertService basecamp
suseInsertService dnsmasq
suseInsertService nexus
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

#==========================================
# remove package docs
#------------------------------------------
rm -rf /usr/share/doc/packages/*
rm -rf /usr/share/doc/manual/*
