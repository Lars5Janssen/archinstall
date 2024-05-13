#! /bin/bash
pacman -Sy reflector
reflector -c Germany --threads 32 --verbose --sort rate --save /etc/pacman.d/mirrorlist
pacman -Syyy
timedatectl set-ntp true
fdisk /dev/nvme0n1
fdisk /dev/nvme1n1
mkswap -L SWAP /dev/nvme0n1p5
swapon /dev/nvme0n1p5
mkfs.btrfs -f -L ROOT /dev/nvme0n1p6
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
pacstrap -K /mnt - < basePackeges.txt
gen-fstab -U /mnt/etc/fstab
arch-chroot /mnt systemctl enable dhcpcd.service
arch-chroot /mnt nvim /etc/fstab --headless -c '%s/subvolid=5,/' -c '%s/subvolid=25[0-9],/' -c 'wq'
arch-chroot /mnt ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime
arch-chroot /mnt hwclock --systohc
arch-chroot /mnt nvim /etc/locale.gen --headless -c '%s/#en.US_UTF-8/en.US_UTF-8/' -c 'wq'
arch-chroot /mnt locale-gen 
arch-chroot /mnt echo 'LANG=en_US.UTF-8' >> /etc/locale.conf
arch-chroot /mnt echo $SETHOSTNAME >> /etc/hostname
arch-chroot /mnt echo "127.0.0.1    localhost"
arch-chroot /mnt echo "::1  localhost"
arch-chroot /mnt echo "127.0.0.1 $SETHOSTNAME.localdomain   $SETHOSTNAME"
arch-chroot /mnt mkinitcpio -P
arch-chroot /mnt passwd
arch-chroot /mnt os-prober
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
arch-chroot /mnt grub-install --target=x84_64-efi --efi-directory=/boot/efi/ --bootloader-id=GRUB
arch-chroot /mnt useradd -m -G wheel $USERNAME
arch-chroot /mnt $USERNAME
arch-chroot /mnt EDITOR='nvim -c ":%s/# %wheel ALL=(ALL:ALL) ALL"' visudo
arch-chroot /mnt ssh-keygen -t ed25519 -C "$SETHOSTNAME" -f "/home/$USERNAME/.ssh/id_ed25519"
