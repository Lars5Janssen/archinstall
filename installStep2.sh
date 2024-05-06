#! /bin/bash
pacstrap -K /mnt - < basePackages.txt

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

nvim /etc/hosts
mkinitcpio -P

passwd        

nvim /etc/default/grub # GRUB_DISABLE_OS_PROBER=false
grub-mkconfig -o /boot/grub/grub.cfg
grub-install --target=x84_64-efi --efi-directory=/boot/efi/ --bootloader-id=GRUB
# does /etc/default/grub exist
os-prober

exit

umount -R /mnt # Try this first | Reference Archwiki install 4 Reboot if a partition is busy
umount -a

shutdown
