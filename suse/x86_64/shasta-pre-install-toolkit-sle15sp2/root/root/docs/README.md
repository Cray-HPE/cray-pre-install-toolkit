# Cray Preinstall Toolkit

This is the Preinstall Toolkit.

## Table of Contents

* [Usage](#usage)
    * [Services](#services)
      * [Basecamp](#configure-basecamp)
        * [Bring Your Own Artifacts!](#bring-your-own-artifacts)
      * [DHCP/TFPT/DNS (DNSMasq)](#configure-dnsmasq)
    * [Interfaces](#interfaces)
      * [lan0](#lan0---internalcray-mgmt-network)
      * [lan1](#lan1---externalsite-customer-network)
      * [vlan002](#vlan002---node-management)
      * [vlan004](#vlan002---node-management)
    * [Partitioning](#partitioning)
      * [Persistence](#persistence)
* [Extras](#extras)
  * [PXE/iPXE Network Installing](#pxeipxe-network-installing)
   * [Boot Parameters](#boot-parameters)
   * [Customizing iPXE](#customizing-ipxe)
     * [Binary](#binary)
     * [Script](#script)

# Usage

## Services

#### Configure Apache2

The default configuration allows:
- Symlinks to be followed
- Listening on all interfaces on port `80` (this is the default web service for the preinstallCD)
- The web root is at `/var/www`

You can configure apache2 like any other by way of the Apache2 manual.

#### Configure Basecamp

Basecamp is the cloud-init metadata server for our NCNs. It will serve
by default over **`port 8080`** on **all** interfaces.

The nodes are told to use this datasource by the `cloud-init` variable value 
in `/var/www/script.ipxe`.

Basecamp serves files from two locations:

```shell script
# Dynamic files, such as templated metadata.
touch /var/www/basecamp/configs/
# Static files, things that everything should get as-is.
touch /var/www/basecamp/static/
```

There's an empty 

For more information, see [the Basecamp Repo](https://stash.us.cray.com/projects/MTL/repos/basecamp/browse).

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

## Interfaces

The interfaces are as follows:

#### lan0 - Internal/Cray (MGMT Network)
- default interface: eth1, eth2
- ifconfig location: `/etc/sysconfig/network/ifcfg-lan0`

The lan0 interface is the inward facing interface, it is used for booting and bootstrapping the initial Shasta stack. This is a bridge instead of a bond as seen on a normal NCN because the PreinstallCD needs to anticipate being ran off any NCN. It can't be assumed a LACP LAGG can be formed, so a bridge is more compatible for bootstrapping.
k
###### Setup

Configure the BOND_SLAVE settings to match your systems NIC names if they are not
eth1 and eth2.

```shell script
ip link show
```

The *member interfaces* do not need to be in a real LACP LAGG on their switch-ports.


#### Edit and reload:
```shell script
/root/bin/sicfg-nic-lan0 10.1.1.1/16
```

#### lan1 - External/Site (customer Network)
- default interface: eth0
- default IP source: dhcp
- ifconfig location: `/etc/sysconfig/network/ifcfg-lan1`

The bridge0 interface may or may not be used depending on if you are in an offline or online 
environment. The interface itself resembles the NCNs actual external interface, which is 
available on a per-site and per-node basis. Not all nodes have direct external interfaces. 
To emulate an airgapped/offline environment, set this bridge's interfaces "down".

###### Edit and reload:
```shell script
/root/bin/sicfg-nic-lan1 172.29.16.5/20 172.29.16.1
```

#### vlan002 - Node Management
- default interface: lan0
- ifconfig location: `/etc/sysconfig/network/ifcfg-vlan002`

This is the node management network, a network partition/broadcast-domain for node communications.

The VLAN ID should be adjusted if your site or VM env. if it requires so.

###### Edit and reload:
```shell script
/root/bin/sicfg-nic-vlan002 10.252.1.1/17
```

#### vlan004 - Hardware Management
- default interface: lan0
- ifconfig location: `/etc/sysconfig/network/ifcfg-vlan004`

This is the hardware management network, strictly for communicating with management devices. IPMI 
commands are issued over this network to control nodes power state during bootstrap.

The VLAN ID should be adjusted if your site requires so.

###### Edit and reload:
```shell script
/root/bin/sicfg-nic-vlan004 10.254.1.1/17
```

### Partitioning

> This is a stub. This will detail how configuration is read from disk.

#### Configs

> This is a stub. This will detail how configuration is read from disk.

#### Persistence

Changes to the Preinstall toolkit's LiveOS will persist, assuming it is running from R/W devices
 (i.e. not a R/O Disc).

# Extras

## PXE/iPXE Network Installing

iPXE is compiled with a chainloading script pointing to:
http://spit/script.ipxe

Below you'll find more information about BYOA (bringing your own artifacts) and how to customize
the compiled binary and the ipxe script.

#### Bring Your Own Artifacts

The kernel, initrd, and SquashFS images can be fetched through the `/var/www/html/script.ipxe`
loader. By default, it expects to find:

- `/var/www/initrd`
- `/var/www/vmlinuz`
- `/var/www/filesystem.squashfs`

###### Ephemeral Mount

`/var/www/ephemeral` isn't special, but the intent is to over a clean drop-area *within* the 
webroot:
- Artifacts can be mounted or downloaded into a clean area.
- The provided scripts can reference known locations.
- The `set-sqfs-links.sh` script scans `/var/www/ephemeral` and populates expected `/var/www` files.

If you choose not to use `/var/www/ephemeral` you'll likely need to read [Customizing iPXE](#customizing-ipxe)

Mount, download, share your artifacts into `/var/www/ephemeral/` and run `/root/set-sqfs-links.sh`
setup links that'll work with the default `/var/www/script.ipxe`.

#### Boot Parameters

Boot parameters are set within `/var/www/script.ipxe`, for starters there's two variables:
1. `kernel-params`: parameters for the SLES OS to boot
2. `ncn-params`: parameters for NCNs
3. `custom-params`: Extra parms users can add w/o modifying original params

These divisions of params are purely abstractions for dividing chunks of parameters, users should
and could change these how they want.

You can automate the edit of `custom-params` (or anything for that matter) with this:

```shell script
sed -i '/custom-params .*/custom-params parm1 param2 param3' /var/www/script.ipxe
```

### Customizing iPXE

There are two points of customization for iPXE:

- Most Edits: The `/var/www/script.ipxe` controls several aspects of the actual boot process
- Rare Edits: The `/root/ipxe-src` outputs a new `ipxe.efi` binary for more customizations

#### Binary

The iPXE EFI binary can be recompiled with more customizations on-the-fly if the current binary is 
insufficient.

By default, [`VLAN_CMD`](https://ipxe.org/buildcfg/vlan_cmd) is defined to allow usage of 
[`vcreate`](https://ipxe.org/cmd/vcreate) and [`vdestroy`](https://ipxe.org/cmd/vdestroy).

The iPXE source used for the initial `ipxe.efi` binary still exists. Explore the `/root/ipxe-src`, 
directory to modify source code. 

To compile it and put it into place:

```shell script
vim chanload.ipxe
make bin-x86_64-efi/ipxe.efi EMBED=chainload.ipxe
cp -pv bin-x86_64-efi/ipxe.efi /var/tftpboot/
chown dnsmasq:tftp /var/tftpboot
```

It will take effect immediately.

#### Script

This is a text file, changes here are applied immediately.

iPXE documentation can be found externally, [here](https://ipxe.org/docs).
