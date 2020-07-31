# Cray Preinstall Toolkit

This is the Preinstall Toolkit.

## Table of Contents

- [Environment](#environment)
    * [Networking](#networking)
    * [Partitioning](#partitioning)
        - [Configs](#configs)
        - [Persistence](#persistence)
- [Function](#function)
    * [PXE/iPXE Network Installing](#pxeipxe-network-installing)
        - [Boot Artifacts](#boot-artifacts)
        - [Boot Parameters](#boot-parameters)

# Usage


#### Configure DNSMasq

You can modify `/etc/dnsmasq.conf` directly *or* use the utility scripts for quick changes:

The first values (the router) must match the IPs given to `spit`'s interfaces. 

```shell script
/root/bin/sicfg-pxe-lan0.sh 10.1.1.1 10.1.2.1 10.1.255.254 10m
/root/bin/sicfg-pxe-vlan002.sh 10.252.1.1 10.252.2.1 10.252.127.254 10m
/root/bin/sicfg-pxe-vlan002.sh 10.254.1.1 10.254.2.1 10.254.127.254 10m

# Restart dnsmaq, and optionally follow the logs to ensure it's up.
systemctl restart dnsmasq
journalctl -xeu dnsmasq -f
```

The interfaces are as follows:

#### lan0 - Internal/Cray (MGMT Network)
    default interface: eth1, eth2
    ifconfig location: /etc/sysconfig/network/ifcfg-lan0

The lan0 interface is the inward facing interface, it is used for booting and bootstrapping the initial Shasta stack. This is a bridge instead of a bond as seen on a normal NCN because the PreinstallCD needs to anticipate being ran off any NCN. It can't be assumed a LACP LAGG can be formed, so a bridge is more compatible for bootstrapping.

###### Setup

Configure the BOND_SLAVE settings to match your systems NIC names if they are not
eth1 and eth2.

```shell script
ip link show
```

The *member interfaces* do not need to be in a real LACP LAGG on their switch-ports.


###### Edit and reload:
```shell script
wicked ifreload lan0 # Reloads configs if wicked detects deltas
# or
wicked ifup lan0 # Forces "up" and a full reload of configs
```

#### lan1 - External/Site (customer Network)
    default interface: eth0
    default IP source: dhcp
    ifconfig location: /etc/sysconfig/network/ifcfg-lan1

The bridge0 interface may or may not be used depending on if you are in an offline or online 
environment. The interface itself resembles the NCNs actual external interface, which is 
available on a per-site and per-node basis. Not all nodes have direct external interfaces. 
To emulate an airgapped/offline environment, set this bridge's interfaces "down".

###### Edit and reload:
```shell script
wicked ifreload lan1 # Reloads configs if wicked detects deltas
# or
wicked ifup lan1 # Forces "up" and a full reload of configs
```

#### vlan002 - Node Management
    default interface: lan0
    ifconfig location: /etc/sysconfig/network/ifcfg-vlan002

This is the node management network, a network partition/broadcast-domain for node communications.

The VLAN ID should be adjusted if your site or VM env. if it requires so.

###### Edit and reload:
```shell script
wicked ifreload vlan002 # Reloads configs if wicked detects deltas
# or
wicked ifup vlan002 # Forces "up" and a full reload of configs
```

#### vlan004 - Hardware Management
    default interface: lan0
    ifconfig location: /etc/sysconfig/network/ifcfg-vlan004

This is the hardware management network, strictly for communicating with management devices. IPMI 
commands are issued over this network to control nodes power state during bootstrap.

The VLAN ID should be adjusted if your site requires so.

###### Edit and reload:
```shell script
wicked ifreload vlan004 # Reloads configs if wicked detects deltas
# or
wicked ifup vlan004 # Forces "up" and a full reload of configs
```


### Partitioning


#### Configs

> This is a stub. This will detail how configuration is read from disk.

#### Persistence

Changes to the Preinstall toolkit's LiveOS will persist, assuming it is running from R/W devices
 (i.e. not a R/O Disc).

# Function

## PXE/iPXE Network Installing

> This is a stub. This functionality is a work-in-progress.

iPXE is compiled with a chainloading script pointing to:
http://spit/script.ipxe

**The hostname is resolvable **

You can edit this script at the local web-root, `/var/www/script.ipxe`

#### Boot Artifacts

The kernel, initrd, and SquashFS images can be fetched through the `/var/www/html/script.ipxe`
loader. By default, it expects to find:

- `/var/www/initrd`
- `/var/www/vmlinuz`
- `/var/www/filesystem.squashfs`

#### Ephemeral

Optionally, you can bring-up artifacts in `/var/www/ephemeral/` and access them directly. The idea
behind the default script, is generic names go into the web-root and versioned items go into 
ephemeral and then get linked.

Mount, download, share your artifacts into `/var/www/ephemeral/` and run `/root/set-sqfs-links.sh`
setup links that'll work with the default `/var/www/script.ipxe`.

#### Boot Parameters

Boot parameters are set within `/var/www/script.ipxe`, for starters there's two variables:
1. `kernel-params`: parameters for the SLES OS to boot
2. `ncn-params`: parameters for NCNs

These divisions of params are purely abstractions for dividing chunks of parameters, users should
and could change these how they want.