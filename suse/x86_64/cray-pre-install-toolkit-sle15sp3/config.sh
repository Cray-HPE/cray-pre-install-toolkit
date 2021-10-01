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
setup-package-repos

#======================================
# Install Packages...
#--------------------------------------
echo "Installing packages from /srv/cray/csm-rpms/packages/cray-pre-install-toolkit/firmware.packages"
install-packages /srv/cray/csm-rpms/packages/cray-pre-install-toolkit/firmware.packages

echo "Installing packages from /srv/cray/csm-rpms/packages/cray-pre-install-toolkit/base.packages"
install-packages /srv/cray/csm-rpms/packages/cray-pre-install-toolkit/base.packages

echo "Installing packages from /srv/cray/csm-rpms/packages/cray-pre-install-toolkit/metal.packages"
install-packages /srv/cray/csm-rpms/packages/cray-pre-install-toolkit/metal.packages

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
alias wipeoff="sed -i 's/metal.no-wipe=0/metal.no-wipe=1/g' /var/www/boot/script.ipxe && set-sqfs-links.sh"
alias wipeon="sed -i 's/metal.no-wipe=1/metal.no-wipe=0/g' /var/www/boot/script.ipxe && set-sqfs-links.sh"
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
# Install kubectl on LiveCD
#--------------------------------------
kubectl_version="1.19.9"
echo "Installing kubectl"
curl -L https://storage.googleapis.com/kubernetes-release/release/v${kubectl_version}/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl
chmod a+x /usr/local/bin/kubectl

#======================================
# Setup Server Firmware Files into the
# webroot.
#--------------------------------------
mkdir -pv /var/www/fw/river/hpe
find /usr/lib/x86_64-linux-gnu/firmware-system* -name  *.flash -exec ln -snf {} /var/www/fw/river/hpe/ \;
find /usr/lib/x86_64-linux-gnu/firmware-ilo5* -name  *.bin -exec ln -snf {} /var/www/fw/river/hpe/ \;


#======================================
# Setup PCIe Firmware Files into the
# webroot.
#--------------------------------------
# This is provided by cray-shasta-mlnx-firmware
ln -snf ../../../usr/share/firmware/ /var/www/fw/pcie

#======================================
# Upload management network firmware
# to the LiveCD
#--------------------------------------
mkdir -pv /var/www/fw/network
cd /var/www/fw/network
wget --mirror -np -nH --cut-dirs=4 -A "*stable*" -nv http://car.dev.cray.com/artifactory/list/integration-firmware

#======================================
# Download and extract River BIOS, BMC, and CMC.
#   The fw images will be available at
#   http://$(ip a show vlan004 | grep inet | awk '{print $2}')/fw/river/{128409,628402,MZ32,MZ62,MZ92}*
#--------------------------------------
declare -r BIOS_RVR_BASE_URL=http://car.dev.cray.com/artifactory/shasta-firmware/HPE/sle15_sp2_ncn/x86_64/release/shasta-1.5/ccs-team
declare dataDir=${DATA_DIR:-/var/www/fw/river} \
        branch="refs%2Fheads%2Fmaster" \
        branch=refs%2Fheads%2Frelease%2Fshasta-1.5 \
        shSvrScriptsUrl=${BIOS_RVR_BASE_URL}/sh-svr-scripts \
        biosUrls="${BIOS_RVR_BASE_URL}/sh-svr-1264up-bios-21.03.00-20211001024239_f54891e.x86_64.rpm ${BIOS_RVR_BASE_URL}/sh-svr-3264-bios-21.03.00-20211001024239_f54891e.x86_64.rpm ${BIOS_RVR_BASE_URL}/sh-svr-5264-gpu-bios-21.03.00-20211001024239_f54891e.x86_64.rpm" \
        line= fileName= curUrl=
printf -- "Downloading River BIOS, BMC, and CMC ... "
mkdir -p ${dataDir}
for curUrl in ${biosUrls}; do #{
  destFileName=${dataDir}/${curUrl##*/}
  curl "${curUrl}" >${destFileName} &
done #}
wait
printf -- "DONE\n"
printf -- "Extracting BIOS, BMC, and CMC into ${dataDir} ... "
for rpmFile in ${biosUrls}; do #{
  rpm2cpio ${dataDir}/${rpmFile##*/} | (cd /var/tmp; cpio -idm)
  extractedBaseDir=/var/tmp/opt/cray/FW/bios/${rpmFile##*/}
  extractedBaseDir=${extractedBaseDir%-bios-*}-bios
  [ -d ${extractedBaseDir}/bios ] && {
    read serverModel< <(find ${extractedBaseDir} -name *F01*.pdf | tail -1)
    serverModel=MZ${serverModel#*MZ}
    serverModel=${serverModel%.pdf}
    #mv ${extractedBaseDir}/bios ${dataDir}/${serverModel}
    cp -a ${extractedBaseDir}/bios ${dataDir}/${serverModel} &
  }

  [ -d ${extractedBaseDir}/bmc ] && {
    read bmcVer< <(find ${extractedBaseDir}/bmc -name *.bin | tail)
    bmcVer=${bmcVer##*/}
    bmcVer=${bmcVer%.bin}
    #mv ${extractedBaseDir}/bmc ${dataDir}/${bmcVer}
    cp -a ${extractedBaseDir}/bmc ${dataDir}/${bmcVer} &
  }

  [ -d ${extractedBaseDir}/cmc ] && {
    read cmcVer< <(find ${extractedBaseDir}/cmc -name *.bin | tail)
    cmcVer=${cmcVer##*/}
    cmcVer=${cmcVer%.bin}
    #mv ${extractedBaseDir}/cmc ${dataDir}/${cmcVer}
    cp -a ${extractedBaseDir}/cmc ${dataDir}/${cmcVer} &
  }
done #}
wait
printf -- "DONE\n"

printf -- "Copying sh-svr-scripts ... "
cp -a /var/tmp/opt/cray/FW/bios/sh-svr-1264up-bios/{sh-svr-scripts,sh-svr-dmi-management,sh-svr-sku-update} ${dataDir}/
printf -- "DONE\n"

printf -- "Removing unused files & directories.\n"
rm -rf ${dataDir}/*rpm /var/tmp/opt
