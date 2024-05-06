#! /bin/bash
loadkeys en
setfont ter-120b

cat /sys/firmware/efi/fw_platform_size # Should echo "64"

ip link
ping archlinux.org

pacman -Sy reflector
reflector -c Germany --threads 16 --verbose --sort rate --score 15 --save /etc/pacman.d/mirrorlist
pacman -Syyy

timedatectl set-ntp true

echo "Now Partition your disks and mount them"
