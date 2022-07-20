#!/bin/bash
#
# MIT License
#
# (C) Copyright 2021-2022 Hewlett Packard Enterprise Development LP
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
#
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
set -e

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
# Add python symlink
#--------------------------------------
ln -snf python3 /usr/bin/python

#======================================
# Source rpm-functions...
#--------------------------------------
echo "Sourcing /srv/cray/csm-rpms/scripts/rpm-functions.sh"
. /srv/cray/csm-rpms/scripts/rpm-functions.sh

#======================================
# Setup Repos...
#--------------------------------------
echo "Setting up package repos from rpm-functions"
# Remove base bootstrap repos in favor of csm-rpm defined repos
cleanup-all-repos
setup-package-repos --pit

#======================================
# Install Packages...
#--------------------------------------
echo "Installing packages from /srv/cray/csm-rpms/packages/cray-pre-install-toolkit/base.packages"
install-packages /srv/cray/csm-rpms/packages/cray-pre-install-toolkit/base.packages

echo "Installing packages from /srv/cray/csm-rpms/packages/cray-pre-install-toolkit/metal.packages"
install-packages /srv/cray/csm-rpms/packages/cray-pre-install-toolkit/metal.packages

#======================================
# Install generic Python tools; ensures
# both the default python and any other
# installed python system versions have 
# basic buildtools.
#--------------------------------------
function setup_python {
    local pythons

    local        pip_ver='21.3.1'
    local      build_ver='0.8.0'
    local setuptools_ver='59.6.0'
    local      wheel_ver='0.37.1'
    local virtualenv_ver='20.15.1'

    readarray -t pythons < <(find /usr/bin/ -regex '.*python3\.[0-9]+')
    printf 'Discovered [%s] python binaries: %s\n' "${#pythons[@]}" "${pythons[*]}"
    for python in "${pythons[@]}"; do
        $python -m pip install -U "pip==$pip_ver" || $python -m ensurepip
        $python -m pip install -U \
            "build==-$build_ver" \
            "setuptools==$setuptools_ver" \
            "virtualenv==$virtualenv_ver" \
            "wheel==$wheel_ver" 
    done
}
setup_python

#======================================
# Lock the kernel...
#--------------------------------------
uname -r
rpm -qa kernel-default
zypper addlock kernel-default

#======================================
# Setup baseproduct link
#--------------------------------------
suseSetupProduct

#======================================
# Activate services
#--------------------------------------
suseInsertService apache2
suseInsertService basecamp
suseInsertService chronyd
suseInsertService dnsmasq
suseInsertService nexus
suseInsertService sshd
systemctl disable mdmon.service
systemctl disable mdmonitor.service
systemctl disable mdmonitor-oneshot.service
systemctl disable mdcheck_start.service
systemctl disable mdcheck_continue.service

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
# Add custom aliases and environment
# variables
#--------------------------------------
cat << EOF >> /root/.bashrc
alias ip='ip -c'
alias ll='ls -l --color'
alias lid='for file in \$(ls -1d /sys/bus/pci/drivers/*/0000\:*/net/*); do printf "% -6s %s\n" "\$(basename \$file)" \$(grep PCI_ID "\$(dirname \$(dirname \$file))/uevent" | cut -f 2 -d '='); done'
alias wipeoff="for script in /var/www/ncn-*/script.ipxe; do sed -i 's/metal.no-wipe=0/metal.no-wipe=1/g' \\\$script; done; wipestat"
alias wipeon="for script in /var/www/ncn-*/script.ipxe; do sed -i 's/metal.no-wipe=1/metal.no-wipe=0/g' \\\$script; done; wipestat"
alias wipestat='grep -o metal.no-wipe=[01] /var/www/ncn-*/script.ipxe'
source <(kubectl completion bash) 2>/dev/null
EOF

#======================================
# Force root user to change password
# at first login.
#--------------------------------------
chage -d 0 root

#======================================
# Goss is used to validate LiveCD health
# at builds, installs and runtime.
#--------------------------------------
# Create symlinks for automated preflight checks
ln -s $GOSS_BASE/automated/livecd-preflight-checks /usr/bin/livecd-preflight-checks
ln -s $GOSS_BASE/automated/ncn-preflight-checks /usr/bin/ncn-preflight-checks
ln -s $GOSS_BASE/automated/ncn-kubernetes-checks /usr/bin/ncn-kubernetes-checks
ln -s $GOSS_BASE/automated/ncn-storage-checks /usr/bin/ncn-storage-checks

#======================================
# Firmware comes from HFP, but we can still keep these directories for convenience and backwards compatibility
#--------------------------------------
mkdir -pv /var/www/fw/river/hpe
mkdir -pv /var/www/fw/network
mkdir -pv /var/www/fw/pcie

#======================================
# Download and extract River BIOS, BMC, and CMC.
#   The fw images will be available at
#   http://$(ip a show vlan004 | grep inet | awk '{print $2}')/fw/river/{128409,628402,MZ32,MZ62,MZ92}*
#--------------------------------------
declare -r BIOS_RVR_BASE_URL=https://stash.us.cray.com/projects/BIOSRVR/repos/bios-rvr/raw
declare dataDir=${DATA_DIR:-/var/www/fw/river} \
        branch="refs%2Fheads%2Fmaster" \
        branch=refs%2Fheads%2Frelease%2Fshasta-1.4 \
        shSvrScriptsUrl=${BIOS_RVR_BASE_URL}/sh-svr-scripts \
        biosUrls="${BIOS_RVR_BASE_URL}/sh-svr-1264up-bios/BIOS/MZ32-AR0-YF_C17_F01.zip ${BIOS_RVR_BASE_URL}/sh-svr-3264-bios/BIOS/MZ62-HD0-YF_C20_F01b.zip ${BIOS_RVR_BASE_URL}/sh-svr-5264-gpu-bios/BIOS/MZ92-FS0-YF_C20_F01.zip" \
        bmcUrl=${BIOS_RVR_BASE_URL}/sh-svr-3264-bios/BMC/128409.zip \
        cmcUrl=${BIOS_RVR_BASE_URL}/sh-svr-3264-bios/CMC/628402.zip \
        line= fileName= curUrl=
mkdir -p ${dataDir}/${shSvrScriptsUrl##*/}
printf -- "Downloading sh-svr-scripts ... "
while read line; do #{
  set ${line} >/dev/null 2>&1
  [ ${#} -eq 4 ] || continue
  fileName=${4}
  curl -sL ${shSvrScriptsUrl}/${fileName}?at=${branch} -o ${dataDir}/${shSvrScriptsUrl##*/}/${fileName} &
done< <(curl -sk ${shSvrScriptsUrl}?at=${branch}) #}
wait
printf -- "DONE\n"
printf -- "Downloading River BIOS, BMC, and CMC ... "
for curUrl in ${biosUrls} ${bmcUrl} ${cmcUrl}; do #{
  curl -sL ${curUrl}?at=${branch} -o ${dataDir}/${curUrl##*/} &
done #}
wait
printf -- "DONE\n"
printf -- "Extracting BIOS, BMC, and CMC into ${dataDir} ... "
for zipArchive in ${biosUrls} ${bmcUrl} ${cmcUrl}; do #{
  python3 -m zipfile -e ${dataDir}/${zipArchive##*/} ${dataDir}/ &
done #}
wait
printf -- "DONE\n"
printf -- "Removing unused files & directories.\n"
find ${dataDir}/1* -maxdepth 1 ! -name fw | tail -n+2 | xargs rm -rf
find ${dataDir}/6* -maxdepth 1 ! -name fw | tail -n+2 | xargs rm -rf
find ${dataDir}/MZ3* -maxdepth 1 ! -name RBU | tail -n+2 | xargs rm -rf
find ${dataDir}/MZ6* -maxdepth 1 ! -name RBU | tail -n+2 | xargs rm -rf
find ${dataDir}/MZ9* -maxdepth 1 ! -name RBU | tail -n+2 | xargs rm -rf
