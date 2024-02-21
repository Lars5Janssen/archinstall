# Steps of my Arch Install for repeatability
These are the steps i do, to install arch.
## Features of installation
- Seperate Home Partition (EXT4)
- BTRFS on Root Partition
- Windows Dual Boot
- GRUB
- Application list for Pacman
# Installprocess
## Windows boot usb
TODO
## Archiso
TODO

## Install Windows
TODO

## MAKE SHURE WINDOWS IS ON A GPT LABLE
check if disk is mbr:
```cmd
diskpart
list disk
```
if the boot drive does not have a "*" under the gpt colum, it is mbr.
Try this from [here](https://learn.microsoft.com/en-us/windows/deployment/mbr-to-gpt) if it is mbr.
```cmd
# Check if disk 0 is the right disk with previous command
MBR2GPT.EXE /validate /disk:0 /allowFullOS
# If no errors
MBR2GPT.EXE /convert /disk:0 /allowFullOS
```
then reboot and enter BIOS Menu and disable BIOS
for me this is disableing CSM

then check results with:
```cmd
diskpart
list disk
```
list disk should return a "*" under the disk you tried to convert.

## If windows is on GPT, procede with archiso

```bash
loadkeys en

setfont ter-120b

# Check for TODO
cat /sys/firmware/efi/fw_platform_size # Should echo "64"

# Are you connected to the Internet
ip link
ping archlinux.org

# Update Mirrorlist for better install
# TODO Post Install?
pacman -Sy reflector
reflector -c Germany --threads 5 --verbose --sort rate --save /etc/pacman.d/mirrorlist
pacman -Syyy

# Set NTP to true

timedatectl set-ntp true

# make fs partitions
lsblk
fdisk /dev/nvme0n1
```

now in fdisk for /dev/nvme0n1:
```fdisk
n ENTER
ENTER # Default 5
+38G ENTER
t ENTER
19 ENTER
n ENTER
ENTER # Default 6
ENTER # Defualt MAX
p ENTER # To verify
w ENTER # If all looks good
```

```bash
fdisk /dev/nvme1n1
```

now in fdsik for /dev/nvme1n1:
```fdisk
g ENTER
n ENTER
ENTER # Default 1
ENTER # Default 2048
ENTER # Default MAX
Y ENTER # If you see a NTFS Signature, remove it
w ENTER
```

```bash
lsblk

mkswap -L SWAP/dev/nvme0n1p5
swapon /dev/nvme0n1p5
mkfs.btrfs -L ROOT /dev/nvme0n1p6
mkfs.ext4 -L HOME /dev/nvme1n1p1

mount /dev/nvme0n1p6 /mnt

btrfs su cr /mnt/@
btrfs su cr /mnt/@tmp
btrfs su cr /mnt/@log
btrfs su cr /mnt/@pkg
btrfs su cr /mnt/@snapshots

umount /mnt

mount -o relatime,space_cache=v2,ssd,compress=lzo,subvol=@ /dev/nvme0n1p6 /mnt
mkdir -p /mnt/{boot/efi,home,var/log,var/cache/pacman/pkg,btrfs,tmp}
mount -o relatime,space_cache=v2,ssd,compress=lzo,subvol=@log /dev/nvme0n1p6 /mnt/var/log
mount -o relatime,space_cache=v2,ssd,compress=lzo,subvol=@pkg /dev/nvme0n1p6 /mnt/var/cache/pacman/pkg
mount -o relatime,space_cache=v2,ssd,compress=lzo,subvol=@tmp /dev/nvme0n1p6 /mnt/tmp
mount -o relatime,space_cache=v2,ssd,compress=lzo,subvolid=5 /dev/nvme0n1p6 /mnt/btrfs
mount /dev/nvme1n1p1 /mnt/home 
mount /dev/nvme0n1p1 /mnt/boot/efi

pacstrap -K /mnt base linux linux-headers inux-firmware nvim base-devel bash-completion btrfs-progs dosfstools grub efibootmgr os-prober networkmanager network-manager-applet dialog mtools reflector cron

genfstab -U /mnt >> /mnt/etc/fstab

arch-chroot /mnt

pacman -S --needed 

nvim /etc/fstab # Remove shit according to [this video](https://www.youtube.com/watch?v=TKdZiCTh3EM)

ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime
hwclock --systohc

nvim /etc/locale.gen    # Uncomment en_US.UTF-8 UTF-8
locale-gen
nvim /etc/locale.conf   # LANG=en_US.UTF-8
nvim /etc/vconsole.conf # KEYMAP=en_US.UTF-8
nvim /etc/hostname      # Set Hostname (funny)
nvim /etc/hosts         # 127.0.0.1{tab}localhost
                        # ::1{tab}localhost
                        # 127.0.1.1{tab}hostname.localdomain{tab}hostname

passwd         # Set Root Password

mkinitcpio -P  # Might not be needed


# GRUB Installation
grub-mkconfig -o /boot/grub/grub.cfg
nvim /etc/default/grub # GRUB_DISABLE_OS_PROBER=false
grub-install --target=x84_64-efi --efi-directory=??? --bootloader-id=GRUB
# does /etc/default/grub exist
os-prober

umount -a 
# OR
umount -R /mnt # Try this first | Reference Archwiki install 4 Reboot if a partition is busy

shutdown

# REMOVE USB STICK

# TURN PC BACK ON

# Post-Install
pacman -S list.txt # VIP

```
