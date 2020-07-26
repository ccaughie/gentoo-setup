#!/bin/bash -xe

# Config variables
rootfs=/dev/sda4
stage3_ver=20200722T214503Z
# End config variables

# Usage: set_if_missing <file> <var> <value>
set_if_missing() {
    if ! grep -qs "$2" "$1" ; then
        echo "$2=\"$3\"" >> $1
    fi
}

set_var() {
    if ! grep -qs "$2" "$1" ; then
        echo "$2=\"$3\"" >> $1
    else
        sed -i "s/$2=.*\$/$2=\"$3\"/" $1
    fi
}

install_stage3() {
    # https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Stage#Downloading_the_stage_tarball
    stage3_tarball=stage3-amd64-${stage3_ver}.tar.xz

    stage3_url=https://bouncer.gentoo.org/fetch/root/all/releases/amd64/autobuilds/${stage3_ver}/${stage3_tarball}

    # Download and unpack the stage 3 tarball
    cd /mnt/gentoo

    if [ ! -f "${stage3_tarball}" ] ; then
        wget ${stage3_url}
        tar xpf ${stage3_tarball} --xattrs-include='*.*' --numeric-owner
    fi
}

configure_make() {
    makeconf=/mnt/gentoo/etc/portage/make.conf

    # https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Stage#Configuring_compile_options
    set_var ${makeconf} COMMON_FLAGS "-march=native -O2 -pipe"

    set_if_missing ${makeconf} MAKEOPTS -j8
    set_if_missing ${makeconf} GENTOO_MIRRORS https://gentoo.osuosl.org/
    set_if_missing ${makeconf} GRUB_PLATFORMS efi-64
    set_if_missing ${makeconf} ACCEPT_LICENSE "* -@EULA"
}

configure_portage() {
    if [ ! -f /mnt/gentoo/etc/portage/repos.conf/gentoo.conf ] ; then
        mkdir --parents /mnt/gentoo/etc/portage/repos.conf
        cp /mnt/gentoo/usr/share/portage/config/repos.conf /mnt/gentoo/etc/portage/repos.conf/gentoo.conf
    fi
}

prepare_chroot() {
    # https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Base#Copy_DNS_info
    cp --dereference /etc/resolv.conf /mnt/gentoo/etc/

    # https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Base#Mounting_the_necessary_filesystems
    mount --types proc /proc /mnt/gentoo/proc
    mount --rbind /sys /mnt/gentoo/sys
    mount --make-rslave /mnt/gentoo/sys
    mount --rbind /dev /mnt/gentoo/dev
    mount --make-rslave /mnt/gentoo/dev

    cp /root/*.sh /mnt/gentoo/root
}

# Mount root filesystem
if ! grep -qs '/mnt/gentoo ' /proc/mounts ; then
    mount $rootfs /mnt/gentoo
fi

install_stage3
configure_make
configure_portage
prepare_chroot
