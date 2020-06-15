# Titanium Linux Build
This repository is a simple build system that allows you to easily cross-compile
U-Boot and/or a Linux kernel for the Elesar Titanium board. It consists of a
script that downloads the required toolchain and clones the necessary
repositories, and Makefiles that simplify the build process.

The resulting kernel is intended to be used with the Debian root
filesystem from [eewiki Linux on
ARM](https://www.digikey.com/eewiki/display/linuxonarm/BeagleBoard-X15),
although it should be possible to use a different filesystem
instead. The Titanium U-Boot includes the boot script patch from
eewiki so that it is compatible with the instructions for BeagleBoard-X15 to
make things easier.

## Prerequisites

In order to use this repository you need to be using a 64-bit PC Linux
distribution (any modern distribution should work) and it needs to have
*git* and standard build tools such as *make* and *gcc* installed. On a
Debian-based distribution such as Ubuntu or Mint install the `build-essential`,
`flex`, and `bison` packages to ensure you have everything. You will need 
approximately 4.0G of free disk space.

## Installation

To start, run the script *prepare.sh*. This will download and install the
toolchain and clone the U-Boot and Linux kernel repositories.

## Building U-Boot

To build U-Boot you simply need to do:

    cd bootloader
    make

When this process has finished the *u-boot* directory will contain the
*MLO* and *u-boot.img* files that need to be installed into the SPI NOR
flash of the Titanium board. Instructions on how to do this are given
later.

## Building the Linux kernel

To build the Linux kernel do the following:

    cd kernel
    make

When this has finished the *deploy* directory will contain the kernel
*zImage* file and tar archives containing the modules and DTBs.

## Creating a microSD card

Follow the [instructions for the
BeagleBoard-X15](https://www.digikey.com/eewiki/display/linuxonarm/BeagleBoard-X15#BeagleBoard-X15-RootFileSystem)
on eewiki but note the following differences:

* You do not need to copy *MLO* and *u-boot.img* to the card because the
Titanium board boots from SPI NOR flash, not from the SD card.

* The path to the *deploy* directory containing the Linux binaries is
different, but it is printed at the end of the kernel build process, as is
the value you should set *kernel_version* to in your environment.

## Updating U-Boot

If you are using a Titanium computer with RISC OS installed and wish
to start Linux using the *!GoLinux* application, ignore this section and
instead copy the *u-boot.img* file into the *!GoLinux* application directory,
setting the file type to *Code*.

The Titanium board boots U-Boot from SPI NOR flash. There is more than one
way of updating this, but this section describes how to do it from the
U-Boot command line, using a FAT formatted microSD card.

1. Copy the files *MLO* and *u-boot.img* to the root directory of a FAT
formatted SD card and insert this in the card slot.

2. Connect a serial terminal to the lower serial connector on the board.
This should be configured for 115200 baud, 8 data bits, one stop bit, no
parity and no flow control.

3. Power on the board. When the message `Hit any key to stop autoboot`
appears, press a key on the terminal to enter the U-Boot command line.

4. Enter the following commands at the U-Boot command line:

        sf probe
        fatload mmc 0 0x82000000 MLO
        sf erase 0x0 0x20000
        sf write 0x82000000 0x0 0x20000
        fatload mmc 0 0x82000000 u-boot.img
        sf erase 0x40000 0x80000
        sf write 0x82000000 0x40000 0x80000

5. Power cycle or reset the board (for example by typing `reset` at the
U-Boot command line) to start the new U-Boot. If you are upgrading from a
different version, you should reset the U-Boot environment to default
values by using the following commands:

        env default -a
        saveenv
        reset

## Updating the kernel

At the end of a build the required files are output in the *deploy* directory
with filenames derived from the version of Linux in the form 4.X.Y-Z.

The three main outputs

* zImage
* dtbs.tar.gz
* modules.tar.gz

all need to be transferred to the SD card.

This can either be done by mounting the SD card on the PC build machine (e.g.
by using a USB card reader), or by transferring the files to the Titanium
board, for example via a network share or removable media, and updating the
root filesystem directly.

The process to extract and copy the files is the same in both cases, but the
target path is different. In the following examples the environment variable
`${sdcard}` is the path to the SD card:

* If you are mounting it on the PC build machine this should be set to the
  path on which the SD card is mounted (for example */media/rootfs*).
* If you are updating the root filesystem on the Titanium board directly,
  the variable should be left unset.

To save having to type the kernel version number many times, set the
following environment variable (the kernel build process prints the value you
should use at the end)

    export kernel_version=4.X.Y-Z

Append the image name to be loaded to U-Boot's environment

    sudo sh -c "echo 'uname_r=${kernel_version}' > ${sdcard}/boot/uEnv.txt"

then proceed to copy the new kernel zImage

    sudo cp -v ${kernel_version}.zImage ${sdcard}/boot/vmlinuz-${kernel_version}

extract the new Device Tree Binaries

    sudo mkdir -p ${sdcard}/boot/dtbs/${kernel_version}/
    sudo tar xf ${kernel_version}-dtbs.tar.gz -C ${sdcard}/boot/dtbs/${kernel_version}/

and extract the new kernel modules

    sudo tar xf ${kernel_version}-modules.tar.gz -C ${sdcard}/

shutdown and power cycle the Titanium board to load the newly installed Kernel.

## Configuring the Linux kernel

The default kernel configuration is generated by *kernel/Makefile* from
*multi_v7_defconfig* plus a set of extra config fragments in the
*ti-linux-kernel/ti_config_fragments* directory - see the Makefile for a
list. These all come unmodified from the upstream TI kernel, except for
the file *titanium.cfg* which contains overrides specifically for the
Titanium board.

If you want to customise the configuration use `make menuconfig` in the
*kernel* directory (not in the *kernel/ti-linux-kernel* directory) so that
it is done with the correct cross-compilation parameters.
