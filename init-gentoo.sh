#!/bin/bash -xe

# Config variables
bootdisk=/dev/sda2
# End config variables

mount ${bootdisk} /boot || echo "Boot disk already mounted"

# https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Base#Configuring_Portage
emerge-webrsync
emerge --sync

# https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Base#Choosing_the_right_profile
eselect profile list

echo "Select a profile using 'eselect profile set N'"
