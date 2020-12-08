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
# Cache docker images.
#--------------------------------------
podman pull sonatype/nexus
podman pull dtr.dev.cray.com/cray/cray-nexus-setup
podman pull dtr.dev.cray.com/metal/cloud-basecamp:$(rpm -q --queryformat '%{VERSION}' basecamp)-$(rpm -q --queryformat '%{RELEASE}' basecamp | cut -d '_' -f2)
podman pull dtr.dev.cray.com/cray/craycli:$(rpm -q --queryformat '%{VERSION}' craycli)-$(rpm -q --queryformat '%{RELEASE}' craycli | cut -d '_' -f2)

#======================================
# Activate services
#--------------------------------------
suseInsertService apache2
suseInsertService chronyd
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
alias refme='zypper \
  --no-gpg-checks \
  --plus-repo=http://dst.us.cray.com/dstrepo/shasta-cd-repo/bloblets/csm/rpms/cray-sles15-sp2-ncn/ \
  up \
  basecamp \
  cray-site-init \
  craycli-wrapper \
  csm-testing \
  docs-csm-install \
  metal-ipxe \
  nexus'
EOF

#======================================
# Force root user to change password
# at first login.
#--------------------------------------
chage -d 0 root

#======================================
# Goss is used to validate LiveCD health
# at builds, installs and runtime.
#
#--------------------------------------
goss_version="0.3.13"
echo "Installing goss"
export GOSS_BASE=/opt/cray/tests/install/ncn
curl -L https://github.com/aelsabbahy/goss/releases/download/v${goss_version}/goss-linux-amd64 -o /usr/bin/goss
chmod a+x /usr/bin/goss

#======================================
# Install kubectl on LiveCD
#
#--------------------------------------
kubectl_version="1.18.6"
echo "Installing kubectl"
curl -L https://storage.googleapis.com/kubernetes-release/release/v${kubectl_version}/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl
chmod a+x /usr/local/bin/kubectl

