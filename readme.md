# Gentoo setup scripts

These are some basic scripts for setting up a Gentoo system based on the [Gentoo Handbook for AMD64](https://wiki.gentoo.org/wiki/Handbook:AMD64).

## Prepare the system for running the setup scripts

1. Boot from the Live CD
2. Enable sshd and set a root password
```
rc-service sshd start
passwd
```
3. From another machine, use scp (or WinSCP) to copy the scripts in this repository to the system (you can use `ip addr show` to find out its IP address, assuming it obtained one from DHCP)
```
scp *.sh root@<ip-address>:~
```
4. Log into the system using ssh/PuTTY

## Configure the disks

Configure the disks using parted or fdisk as described [here](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Disks). The scripts assume that partitions exist with the following labels:

* rootfs: The partition used for the root filesystem
* boot: The EFI boot partition
* swap: The swap partition

Make sure to format the boot partition as FAT32, e.g.

```
mkfs.fat -F 32 /dev/sda2
```

## Review the scripts

Most of the scripts have variables defined near the top which specify things like installation disks and network information. Change these as necessary to suit your system.

## Prepare the root partition

Run the `prepare-gentoo.sh` script to prepare the root partition

```
./prepare-gentoo.sh
```

## Chroot and initialize the system

The step above should have copied these scripts to /mnt/gentoo/root, so that they'll be available when you chroot to the new system.

```
chroot /mnt/gentoo /bin/bash
cd
./init-gentoo.sh
```

When the above has finished running, it will list the available profiles, with the default highlighted with `*`. If you want to use a different profile from the default, do

```
eselect profile set N
```

where `N` is the profile number.

## Run the main installer

```
./install-gentoo.sh
```

## Set a root password and/or create an admin user

```
passwd
```

```
emerge app-admin/sudo
visudo  # You may want to uncomment "%wheel ALL=(ALL) ALL"
useradd -m -G users,wheel -s /bin/bash <myusername>
passwd <myusername>
```

## Unmount and reboot

```
exit
./unmount-gentoo.sh
reboot
```