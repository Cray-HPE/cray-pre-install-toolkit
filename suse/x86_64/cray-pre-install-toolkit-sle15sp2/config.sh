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
# Install CRAY Specific RPMs
#--------------------------------------
zypper \
  --no-gpg-checks \
  --plus-repo=http://car.dev.cray.com/artifactory/shasta-premium/MTL/sle15_sp2_ncn/x86_64/dev/master/ \
  --plus-repo=http://car.dev.cray.com/artifactory/shasta-premium/MTL/sle15_sp2_ncn/noarch/dev/master/ \
  --plus-repo=http://car.dev.cray.com/artifactory/shasta-premium/SPET/sle15_sp2_ncn/noarch/dev/master/ \
  in \
  -y \
  basecamp \
  cray-site-init \
  craycli-wrapper \
  csm-testing \
  metal-ipxe \
  docs-csm-install \
  nexus

#======================================
# Cache docker images.
#--------------------------------------
podman pull sonatype/nexus
podman pull dtr.dev.cray.com/metal/cloud-basecamp
podman pull dtr.dev.cray.com/cray/cray-nexus-setup
podman pull dtr.dev.cray.com/cray/craycli

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
# Purge zypper repos, users must BYOR.
#--------------------------------------
zypper --verbose clean --all
rm -r /etc/zypp/repos.d/*
cp /dev/null /var/log/zypper.log

#======================================
# Set hostname to pit
#--------------------------------------
echo "pit" > /etc/hostname

#======================================
# Add custom aliases
#--------------------------------------
cat << EOF >> /root/.bashrc
alias ip='ip -c'
alias ll='ls -l --color'
alias lid='for file in \$(ls -1d /sys/bus/pci/drivers/*/0000\:*/net/*); do printf "% -6s %s\n" "\$(basename \$file)" \$(grep PCI_ID "\$(dirname \$(dirname \$file))/uevent" | cut -f 2 -d '='); done'
EOF

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

# Goss is used to validate LiveCD health at builds, installs and runtime.
goss_version="0.3.13"
echo "Installing goss"
curl -L https://github.com/aelsabbahy/goss/releases/download/v${goss_version}/goss-linux-amd64 -o /usr/bin/goss
chmod a+x /usr/bin/goss

# install kubectl on LiveCD
kubectl_version="1.18.6"
echo "Installing kubectl"
curl -L https://storage.googleapis.com/kubernetes-release/release/v${kubectl_version}/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl
chmod a+x /usr/local/bin/kubectl