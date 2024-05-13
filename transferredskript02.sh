#! /bin/bash
cp userspace.txt /mnt/
arch-chroot /mnt git clone git@github.com:Lars5Janssen/dotfiles.git /home/$USERNAME/
arch-chroot /mnt stow dotfiles/
arch-chroot /mnt EDITOR='nvim -c ":35s/#Color/Color/" -c ":37s/#ParallelDownloads = 8/ParallelDownloads = 16\nILoveCandy/" -c ":%s/#\[multilib\]/\[multilib\]/" -c ":%s!#Include = /etc/pacman.d/mirrorlist!Include = /etc/pacman.d/mirrorlist!"'
arch-chroot /mnt su -c "sudo pacman -S - < /userspace.txt" $USERNAME
umount -a
reboot
