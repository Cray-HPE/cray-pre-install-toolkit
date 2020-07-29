# Pre-install Toolkit

This repo contains the pre-install toolkit source, a kiwi description
for building a JeOS ISO that can be used to boot an NCN for installation
of the Shasta software stack.


## Overview of repo contents

The repo is comprised of the following content:

* Subset of content from origin repo:
  https://github.com/OSInside/kiwi-descriptions.git
* DST build source
* Kiwi descriptions


### Subset of content from origin repo

* LICENSE
    * This file was brought into the repo from the origin repo that
      provided the suse/x86_64/suse-leap-15.1-JeOS kiwi description.
      https://github.com/OSInside/kiwi-descriptions.git
* suse/x86_64/suse-leap-15.1-JeOS
    * The descriptions to generate JeOS. It was modified to build in
      DST, so is no longer the original.


### DST build source

* Jenkinsfile
    * Used by DST pipeline to execute builds of the pre-install toolkit.
* build.sh
    * The script executed to run the kiwi-ng tool and compile the
      desired image, defined by the DESC_DIR in the script.
* img-rename.sh
    * Script used to rename the image to match our naming standard.


### Kiwi descriptions

* suse/x86_64/suse-leap-15.1-JeOS
    * The original Leap 15.1 JeOS description, modified to build in the DST
    pipeline.

* suse/x86_64/cray-sles15sp1-JeOS
    * Cray developed description, derived from the Leap 15.1
      description, using SLE 15 SP1 as the base. This description is
      used to generate the JeOS image for the Live OS Media to boot an
      NCN for installation.
      
* suse/x86_64/cray-sles15sp2-JeOS
    * Cray developed description, derived from the Leap 15.2
      description, using SLE 15 SP2 as the base. This description is
      used to generate the JeOS image for the Live OS Media to boot an
      NCN for installation.


## Anatomy of a description

The following files and directories are found in the
`suse/x86_64/cray-sles15sp2-JeOS` description:

* config.sh
    * Configuration shell script that runs after the target image
      tree has been prepared. Used to fine tune the target image.
* config.xml
    * The description file, and only required component of a
      description. It directs how the kiwi command will build the
      image.
* root
    * Overlay tree directory containing files and directories that will
      be copied to the target image tree as it is prepared. Add files
      and directories that are needed in the target image. For example,
      `root/etc/motd` for message of the day; rules for udev configuration
      in `root/etc/udev/rules.d/70-persistent-net.rules`; network
      configuration scripts in `root/sysconfig/network/ifcfg-lan0`.


## How to update the installation image description

The description used to generate installation images for the NCN nodes
is: `suse/x86_64/cray-sles15sp2-JeOS`. Modify the content within that
subdirectory to add new packages to the image or change the image
definition.

Documentation for KIWI NG can be found here:

> https://osinside.github.io/kiwi/index.html

The image description XML schema can be found here:

> https://osinside.github.io/kiwi/schema.html

The type of image built is `iso`.


### Editing Rules

1. Do not use hardtabs.
2. Nested tags should be indented.
3. Use 4-space indentation.
4. 80 character line limits are not a virtue in XML.


### How a package is selected for installation

Repos can be assigned a priority. Priority values range from 1 to 99.
Priority 1 has the highest precedence and priority 99 has the lowest
precedent.  If no priority is specified for a repo it is assumed to have
a priority of 99.

Packages in the description can be specified by the name of the package,
or a full URL to the package can be provided. The name string can
contain the generic package name or the generic package name and any
addition characters to identify a particular version or flavor. If the
URL is specified that exact package is installed.

When a package is specified by name, the package will be installed from
the repo with the highest precedence (lowest priority number). If the
package is found in multiple repos of the same precedence, the package
with the highest version will be installed, provided a specific version
number was not specified in the name.

### Adding packages

Packages are added between the `<packages>` and `</packages>` tags.
There will be multiple such packages tags, each defined by a `type`
value. New packages are usually added to the packages block with
`type=image`.

The image types are defined as:

* bootstrap
    * Packages installed in first phase of an image build to fill empty
      root directory with bootstrap data.

* image
    * Packages installed after the bootstrap phase as a chroot
      operation.

* iso
    * Packages installed during chroot operation if the image type is
      `iso`.

* oem
    * Packages installed during chroot operation if the image type is
      `oem`.


The package entry must be in the following format:

    <package name="NAME_OR_URL">

Additional optional attributes include:

* arch
    * System architecture name matching the `uname -m` information.

* bootdelete
    * Indicates if package should be removed from boot image (initrd).
      Only evaluated if `bootinclude` attribute is also specified.

* bootinclude
    * Indicates if package should be part of the boot image (initrd).

The use of the additional optional attributes would be unusual.


### Adding repos

Package repositories, repos, are specified using the `<source/>` tag
nested between the `<repository>` and `</repository>` tags.

There are many attributes that can be specified in the `<repository>`
tag, the commonly used being:

* type
  * The type of repository. It will be `rpm-md` for RPM repos.

* alias
  * Alias name used for the repo; do not use the same alias name twice
    as it will result in the first instance metadata being overwritten.

* priority
  * The priority, precedence order, of the repo. A lower priority number
    repo has a higher precedence. Priority 1 is reserved for developer
    use and should not be used outside of development use cases.
    Priority 2 is reserved for the distribution base operating system
    repo. Priority 3 is reserved for additional distribution operating
    system repos.


The `<source/>` tag contains one required attribute, `source`, to
set the path or URL to the repository.

The repository format would appear like:

    <repository type="rpm-md" alias="nickname-for-repo">
        <source path="http://url-path"/>
    </repository>


### Changing image preferences

The image to build is identified by the type, such as `iso`, `oem`,
`vmx`, and many others. The preferences for the image are specified
between the `<preferences>` and `</preferences>` tags.  Nested within
those tags, the most important tag for controlling what is built for an
image is the `<type/>` tag.

The `<type/>` tag contains a number of attributes that determine what
type of image is generated and how it is generated. The `image`
attribute is used to set the type of image and will be one of the
following: `btrfs, clicfs, cpio, docker, ext2, ext3, ext4, iso, oem,
pxe, squashfs, tbz, vmx, xfs, oci`.

The pre-install toolkit will be using the `iso` image type. Additional
information for the additional attributes that can be specified can be
found in the schema document at:

> https://osinside.github.io/kiwi/schema.html#id54


<!--
vim: tw=72 et sw=4 ts=4
-->
