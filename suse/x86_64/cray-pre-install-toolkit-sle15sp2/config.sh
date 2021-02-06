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
suseInsertService apache2
suseInsertService chronyd
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
# Add custom aliases and environment
# variables
#--------------------------------------
cat << EOF >> /root/.bashrc
alias ip='ip -c'
alias ll='ls -l --color'
alias lid='for file in \$(ls -1d /sys/bus/pci/drivers/*/0000\:*/net/*); do printf "% -6s %s\n" "\$(basename \$file)" \$(grep PCI_ID "\$(dirname \$(dirname \$file))/uevent" | cut -f 2 -d '='); done'
export GOSS_BASE=/opt/cray/tests/install/livecd
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
goss_version="0.3.13"
echo "Installing goss"
export GOSS_BASE=/opt/cray/tests/install/livecd
curl -L https://github.com/aelsabbahy/goss/releases/download/v${goss_version}/goss-linux-amd64 -o /usr/bin/goss
chmod a+x /usr/bin/goss
# Create symlinks for automated preflight checks
ln -s $GOSS_BASE/automated/livecd-preflight-checks /usr/bin/livecd-preflight-checks
ln -s $GOSS_BASE/automated/ncn-preflight-checks /usr/bin/ncn-preflight-checks
ln -s $GOSS_BASE/automated/ncn-kubernetes-checks /usr/bin/ncn-kubernetes-checks
ln -s $GOSS_BASE/automated/ncn-storage-checks /usr/bin/ncn-storage-checks

#======================================
# Install kubectl on LiveCD
#--------------------------------------
kubectl_version="1.18.6"
echo "Installing kubectl"
curl -L https://storage.googleapis.com/kubernetes-release/release/v${kubectl_version}/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl
chmod a+x /usr/local/bin/kubectl

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
#   http://pit/fw/river/{128409,628402,MZ32,MZ62,MZ92}*
#   http://$(ip a show vlan004 | grep inet | awk '{print $2}'/fw/river/{128409,628402,MZ32,MZ62,MZ92}*
#--------------------------------------
declare -r BIOS_RVR_BASE_URL=https://stash.us.cray.com/projects/BIOSRVR/repos/bios-rvr/raw
declare ephemeralDataDir=${EPH_DATA_DIR:-/var/www/fw/river} \
        branch=refs%2Fheads%2Frelease%2Fshasta-1.4 \
        shSvrScriptsUrl=${BIOS_RVR_BASE_URL}/sh-svr-scripts \
        biosUrls="${BIOS_RVR_BASE_URL}/sh-svr-1264up-bios/BIOS/MZ32-AR0-YF_C20_F01.zip ${BIOS_RVR_BASE_URL}/sh-svr-3264-bios/BIOS/MZ62-HD0-YF_C20_F01b.zip ${BIOS_RVR_BASE_URL}/sh-svr-5264-gpu-bios/BIOS/MZ92-FS0-YF_C20_F01.zip" \
        bmcUrl=${BIOS_RVR_BASE_URL}/sh-svr-3264-bios/BMC/128409.zip \
        cmcUrl=${BIOS_RVR_BASE_URL}/sh-svr-3264-bios/CMC/628402.zip \
        curUrl=
mkdir -p ${ephemeralDataDir}/${shSvrScriptsUrl##*/}
printf -- "Downloading River BIOS, BMC, and CMC ... "
for curUrl in ${biosUrls} ${bmcUrl} ${cmcUrl}; do #{
  curl -sL ${curUrl}?at=${branch} -o ${ephemeralDataDir}/${curUrl##*/} &
done #}
(for f in `/usr/bin/curl -s ${shSvrScriptsUrl}?at=${branch} | awk '{print $NF}'`; do /usr/bin/curl -s ${shSvrScriptsUrl}/${f}?at=${branch} >${ephemeralDataDir}/${shSvrScriptsUrl##*/}/${f} & done )
wait
printf -- "DONE\n"
printf -- "Removing unused files & directories.\n"
find ${ephemeralDataDir}/1* -maxdepth 1 ! -name fw | tail -n+2 | xargs rm -rf
find ${ephemeralDataDir}/6* -maxdepth 1 ! -name fw | tail -n+2 | xargs rm -rf
find ${ephemeralDataDir}/MZ3* -maxdepth 1 ! -name RBU | tail -n+2 | xargs rm -rf
find ${ephemeralDataDir}/MZ6* -maxdepth 1 ! -name RBU | tail -n+2 | xargs rm -rf
find ${ephemeralDataDir}/MZ9* -maxdepth 1 ! -name RBU | tail -n+2 | xargs rm -rf
