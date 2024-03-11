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
### Disable Fast Reboot
After windows install, go to
Control Panel -> Hardware and Sound -> Change what the power buttons do -> Change settings that are currently unacailable -> Uncheck "Turn on fast startup (recommended)"

then reboot into windows and procede

### Format C: with gpt label

check if disk is mbr:
```cmd
diskpart
list disk
```
if the boot drive does not have a "*" under the gpt colum, it is mbr.
Try this from [here](https://learn.microsoft.com/en-us/windows/deployment/mbr-to-gpt) if it is mbr.
```cmd
:: Check if disk 0 is the right disk with previous command
MBR2GPT.EXE /validate /disk:0 /allowFullOS
:: If no errors
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

## ArchISO

### Basic Config of ArchISO

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
reflector -c Germany --threads 16 --verbose --sort rate --score 15 --save /etc/pacman.d/mirrorlist
pacman -Syyy

# Set NTP to true

timedatectl set-ntp true
```
### FS Partitioning
```bash
lsblk
fdisk /dev/nvme0n1
```

now in fdisk for /dev/nvme0n1:
```fdisk
n ENTER
ENTER # Default 5
ENTER # Default bla bla bla
+38G ENTER
t ENTER
ENTER # Default 5
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
### Filesystem creation and mount (BTRFS Stuff)
```bash
lsblk

mkswap -L SWAP /dev/nvme0n1p5
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

mount -o relatime,compress=zstd,subvol=@ /dev/nvme0n1p6 /mnt
mkdir -p /mnt/{boot/efi,home,var/log,var/cache/pacman/pkg,btrfs,tmp}
mount -o relatime,compress=zstd,subvol=@tmp /dev/nvme0n1p6 /mnt/tmp
mount -o relatime,compress=zstd,subvol=@log /dev/nvme0n1p6 /mnt/var/log
mount -o relatime,compress=zstd,subvol=@pkg /dev/nvme0n1p6 /mnt/var/cache/pacman/pkg
mount -o relatime,compress=zstd,subvolid=5 /dev/nvme0n1p6 /mnt/btrfs
mount /dev/nvme0n1p1 /mnt/boot/efi
mount /dev/nvme1n1p1 /mnt/home 
```
### Pacstrap
```bash
pacstrap -K /mnt base linux linux-headers linux-firmware neovim base-devel bash-completion btrfs-progs dosfstools grub efibootmgr os-prober networkmanager dialog mtools reflector cron ntfs-3g amd-ucode nvidia-dkms git# Use intle-ucode if you have intel dhcpcd

genfstab -U /mnt >> /mnt/etc/fstab

arch-chroot /mnt 

systemctl enable dhcpcd.service

nvim /etc/fstab # Remove shit according to [this video](https://www.youtube.com/watch?v=TKdZiCTh3EM)

ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime
hwclock --systohc

nvim /etc/locale.gen    # Uncomment en_US.UTF-8 UTF-8
locale-gen

echo "LANG=en_US.UTF-8" >> /etc/locale.conf 
echo "KEYMAP=en_US.UTF-8" >> /etc/vconsole.conf 
echo "YOURHOSTNAME" >> /etc/hostname 

nvim /etc/hosts         # 127.0.0.1{tab}localhost
                        # ::1{tab}localhost
                        # 127.0.1.1{tab}hostname.localdomain{tab}hostname
mkinitcpio -P

passwd         # Set Root Password
```
### GRUB
```bash
grub-mkconfig -o /boot/grub/grub.cfg
nvim /etc/default/grub # GRUB_DISABLE_OS_PROBER=false
grub-mkconfig -o /boot/grub/grub.cfg
grub-install --target=x84_64-efi --efi-directory=/boot/efi/ --bootloader-id=GRUB
# does /etc/default/grub exist
os-prober

exit

umount -R /mnt # Try this first | Reference Archwiki install 4 Reboot if a partition is busy
umount -a

shutdown

# REMOVE USB STICK

# TURN PC BACK ON
```
## Post Installation
### Supress Journald Error during shutdown
edit /etc/systemd/journald.conf
Under [Journal] add "Storage=volatile" like this
```toml
/.../
[Journal]
Storage=volatile
/.../
```
### Create User
```bash
useradd -m -G wheel username
passwd username
EDITOR=nvim visudo # uncomment wheel
```
exit and login as new user. Test ```sudo```

### Pacman.conf
```bash
sudoedit /etc/pacman.conf # Enable Paralell Downloads
                          # Enable Color
                          # Add 'ILoveCandy'
```

### AUR
```bash
git clone https://aur.archlinux.org/paru.git && cd paru && makepkg -si && cd .. && rm -r paru
```

### Snapper
```bash
pacman -S snapper
snapper -c root create-config /
btrfs sub del /.snapshots/
mkdir /.snapshots
nvim /etc/fstab
mount /.snapshots/
paru -S grub-btrfs
nvim /etc/default/grub # Add:
                       # GRUB_BTRFS_CREATE_ONLY_HARMONIZED_ENTRIES="true"
                       # GRUB_BTRFS_LIMIT="10"

nvim /etc/snapper/configs/root  # Set
                                # NUMBER_CLEANUP="yes"
                                # NUMBER_MIN_AGE="0"
                                # NUMBER_LIMIT="12"
                                # NUMBER_LIMIT="10"
                                # TIMELINE_CREAT="no"

systemctl enable cronie.service
systemctl start cronie.servicee

sudo pacman -S snap-pac
paru -S snap-pac-grub
```

#### How to Rollback with GRUB
- Use GRUB to boot into snapshot
- ```sudo snapper rollback```
- ```sudo reboot```
- select previous snapshot
  - input number you got from rollback at 3 places:
  - 1: at the kernel
  - 2: at the root fs/volume
  - 3: at the initramfs
- press F10
- Boot into corrosponding snapshot number from rollback. This should be writable
- ```sudo grub-mkconfig -o /boot/grub/grub.cfg```
- ```sudo grub-install -target=x84_64-efi --efi-directory=/boot/efi/ --bootloader-id=GRUB```
- Reboot into GRUB, confirm that default snapshot is Number from rollback

### Dotfiles Repo
```bash
sudo pacman -S openssh
ssh-keygen -t ed25519 -C "arch"
eval "$(ssh-agent)"
shh-add ~/.ssh/*
cat ~/.ssh/id_ed25519.pub # past to Github (Or something else fuck github)
git clone git@github.com:Lars5Janssen/dotfiles.git
sudo pacman -S stow starship alacritty zoxide ranger
```

### Hpyrland
```bash
sudo pacman -S hyprland pipewire wireplumber mako polkit nextcloud-client kdeconnect-app keepassxc waybar
sudo echo "options nvidia_drm modeset=1" >> /etc/modprobe.d/nvidia_drm.conf
sudo nvim /etc/mkinitcpio.conf  # Add "/etc/modprobe.d/nividia_drm.conf" to FILES=() like this:
                                # FILES=(/etc/modprobe.d/nvidia_drm.conf)

reboot

cat /sys/module/nvidia_drm/parameters/modeset # Should return Y
```
