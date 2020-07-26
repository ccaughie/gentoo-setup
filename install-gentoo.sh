#!/bin/bash -xe

# Config variables
bootdisk=/dev/sda2
timezone="America/Los_Angeles"
hostname="gentoo"
dnsdomain="lan"
primary_nic=eno1
ipaddress="192.168.1.5"
netmask="255.255.255.0"
broadcast="192.168.1.255"
gateway="192.168.1.1"
# End config variables

update_world_set() {
    # https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Base#Updating_the_.40world_set
    emerge --verbose --update --deep --newuse @world
}

set_timezone() {
    # https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Base#Timezone
    echo ${timezone} > /etc/timezone
    emerge --config sys-libs/timezone-data
}

configure_locales() {
    # https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Base#Configure_locales
    cat > /etc/locale.gen <<EOF
en_US ISO-8859-1
en_US.UTF-8 UTF-8
EOF
    locale-gen

    localenum="$(eselect locale list | grep en_US\.utf8$ | sed 's/.*\[\([0-9]\+\)\].*$/\1/')"
    eselect locale set ${localenum}
    env-update
}

configure_kernel() {
    # https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Kernel#Default:_Manual_configuration
    emerge sys-kernel/gentoo-sources sys-apps/pciutils
    cd /usr/src/linux
    make defconfig
    make -j8 && make modules_install
    make install

    # https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Kernel#Optional:_Building_an_initramfs
    emerge sys-kernel/genkernel
    genkernel --install initramfs

    emerge sys-kernel/linux-firmware
}

configure_fstab() {
    # https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/System#Creating_the_fstab_file
    if ! grep -qs "^PARTLABEL=rootfs" /etc/fstab ; then
        echo "PARTLABEL=rootfs / ext4 noatime 0 1" >> /etc/fstab
    fi

    if ! grep -qs "^PARTLABEL=boot" /etc/fstab ; then
        echo "PARTLABEL=boot /boot vfat noauto,noatime 1 2" >> /etc/fstab
    fi

    if ! grep -qs "^PARTLABEL=swap" /etc/fstab ; then
        echo "PARTLABEL=swap none swap sw 0 0" >> /etc/fstab
    fi
}

configure_network() {
    # https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/System#Host_and_domain_information
    cat > /etc/conf.d/hostname <<EOF
hostname="${hostname}"
EOF

    # https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/System#Configuring_the_network
    emerge --noreplace net-misc/netifrc

    cat > /etc/conf.d/net <<EOF
dns_domain_lo="${dnsdomain}"

config_${primary_nic}="${ipaddress} netmask ${netmask} brd ${broadcast}"
routes_${primary_nic}="default via ${gateway}"
EOF

    # https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/System#Automatically_start_networking_at_boot
    cd /etc/init.d
    ln -s net.lo net.${primary_nic}
    rc-update add net.${primary_nic} default

    # https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/System#The_hosts_file
    cat > /etc/hosts <<EOF
127.0.0.1   ${hostname}.${dnsdomain} ${hostname} localhost
::1         localhost
EOF
}

install_tools() {
    # https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Tools
    emerge app-admin/sysklogd sys-process/cronie sys-fs/e2fsprogs sys-fs/dosfstools net-misc/dhcpcd app-admin/sudo

    rc-update add sysklogd default
    rc-update add cronie default
    rc-update add sshd default
}

configure_bootloader() {
    # https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Bootloader#Default:_GRUB2
    emerge sys-boot/grub:2

    grub-install --target=x86_64-efi --efi-directory=/boot --removable
    grub-mkconfig -o /boot/grub/grub.cfg
}

update_world_set
set_timezone
configure_locales
configure_kernel
configure_fstab
configure_network
install_tools
configure_bootloader
