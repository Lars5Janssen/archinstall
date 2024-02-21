# Steps of my Arch Install for repeatability
These are the steps i do, to install arch.
## Features of installation
- Seperate Home Partition (EXT4)
- BTRFS on Root Partition
- Windows Dual Boot
- GRUB
- Application list for Pacman
# Commands of install

```bash
loadkeys en

setfont ter-132b

cat /sys/firmware/efi/fw_platform_size

ip link
ping archlinux.org

timedatectl
# set correct timezone may be not neccecary

# make fs partitions
# swap (8g), root(btrfs), Windows Partitions...
# How to formate BTRFS?
# Home
# format partitions correctly

# mount the file systems

pacstrap -K /mnt base linux linux-firmware nvim grub efibootmgr grub-install os-prober

genfstab -U /mnt >> /mnt/etc/fstab

arch-chroot /mnt

ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime
hwclock --systohc

nvim /etc/locale.gen    # Uncomment en_US.UTF-8 UTF-8
locale-gen
nvim /etc/locale.conf   # LANG=en_US.UTF-8
nvim /etc/vconsole.conf # KEYMAP=en_US.UTF-8
nvim /etc/hostname      # Set Hostname (funny)

mkinitcpio -P  # Might not be needed

passwd         # Set Root Password

# GRUB Installation
grub-install --target=x84_64-efi --efi-directory=??? --bootloader-id=GRUB
# does /etc/default/grub exist
nvim /etc/default/grub # GRUB_DISABLE_OS_PROBER=false
os-prober
grub-mkconfig -o /boot/grub/grub.cfg

umount -a 
# OR
umount -R /mnt # Try this first | Reference Archwiki install 4 Reboot if a partition is busy

shutdown

# REMOVE USB STICK

# TURN PC BACK ON

# Post-Install
pacman -S list.txt # VIP

```
