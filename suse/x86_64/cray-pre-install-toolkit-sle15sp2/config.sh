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
echo "Installing packages from /srv/cray/csm-rpms/packages/cray-pre-install-toolkit/base.packages"
install-packages /srv/cray/csm-rpms/packages/cray-pre-install-toolkit/base.packages

echo "Installing packages from /srv/cray/csm-rpms/packages/cray-pre-install-toolkit/metal.packages"
install-packages /srv/cray/csm-rpms/packages/cray-pre-install-toolkit/metal.packages

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
