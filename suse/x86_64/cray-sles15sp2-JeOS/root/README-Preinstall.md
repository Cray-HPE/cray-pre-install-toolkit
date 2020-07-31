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

# Environment

### Networking

There are two bridge devices that should be adjusted for the Preinstall's environment.

There are also two VLAN devices that resemble would-be NCN interfaces, these may/should also be 
adjusted for the Preinstall's environment.

DHCPD is set to reload when interfaces are reconfigured. To change this, modify /etc/sysconfig/dhcpd:

> ##### Note:
> By default, the Preinstall Toolkit uses the HPE approved network blocks to conform with HPE lab
> standards.  This helps minimize risks to local labs/sites by avoiding serving clashing DNS/DHCP
>  and other services from infrastructure.
NOTE 

The interfaces are as follows:

#### bridge0 - External/Site
    default interface: eth0
    default IP source: dhcp
    ifconfig location: /etc/sysconfig/network/ifcfg-bridge0

The bridge0 interface may or may not be used depending on if you are in an offline or online 
environment. The interface itself resembles the NCNs actual external interface, which is 
available on a per-site and per-node basis. Not all nodes have direct external interfaces. 
To emulate an airgapped/offline environment, set this bridge's interfaces "down".

###### Edit and reload:
```shell script
wicked ifreload bridge0 # Reloads configs if wicked detects deltas
# or
wicked ifup bridge0 # Forces "up" and a full reload of configs
```

#### bond0 - Internal/Cray
    default interface: eth1, eth2
    default IP source: 192.168.64.1/20
    ifconfig location: /etc/sysconfig/network/ifcfg-bond0

The bridge1 interface is the inward facing interface, it is used for booting and bootstrapping the initial Shasta stack. This is a bridge instead of a bond as seen on a normal NCN because the PreinstallCD needs to anticipate being ran off any NCN. It can't be assumed a LACP LAGG can be formed, so a bridge is more compatible for bootstrapping.

###### Edit and reload:
```shell script
wicked ifreload bond0 # Reloads configs if wicked detects deltas
# or
wicked ifup bond0 # Forces "up" and a full reload of configs
```

#### vlan002 - Node Management
    default interface: bond0
    default IP source: 192.168.80.1/20
    ifconfig location: /etc/sysconfig/network/ifcfg-vlan002

This is the node management network, a network partition/broadcast-domain for node communications.

The VLAN ID should be adjusted if your site requires so.

###### Edit and reload:
```shell script
wicked ifreload vlan002 # Reloads configs if wicked detects deltas
# or
wicked ifup vlan002 # Forces "up" and a full reload of configs
```

#### vlan004 - Hardware Management
    default interface: bond0
    default IP source: 192.168.96.1/20
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

The Preinstall

#### Configs

> This is a stub. This will detail how configuration is read from disk.

#### Persistence

Changes to the Preinstall toolkit's LiveOS will persist, assuming it is running from R/W devices
 (i.e. not a R/O Disc).

# Function

## PXE/iPXE Network Installing

> This is a stub. This functionality is a work-in-progress.

iPXE is compiled with a chainloading script pointing to:
http://cray-livecd.local/script.ipxe

You can edit this script at the local web-root, `/var/www/script.ipxe`

#### Boot Artifacts

The kernel, initrd, and SquashFS images can be fetched through the `/var/www/html/script.ipxe`
loader. By default, it expects to find:

- `/var/www/initrd`
- `/var/www/linux`
- `/var/www/ncn-image.squashfs`

Optionally, you can bring-up artifacts in `/var/www/ephemeral/` and access them directly. The idea
behind the default script, is generic names go into the web-root and versioned items go into 
ephemeral and then get linked.

#### Boot Parameters

> This is a stub.