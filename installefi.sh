#! /bin/bash

funerror(){
    whiptail --title $1 --textbox errorfile 20 60
    exit $2
}
systemctl stop reflector.service
#setfont /usr/share/kbd/consolefonts/iso01-12x22.psfu.gz
#whiptail --title "FBI WARNING" --yesno "FIRST YOU SHOULD PARTITION THE DISK." 12 35 || exit 0

whiptail --title "SET HOSTNAME" --infobox "\n WATTING PLEASE" 12 35
HOST_NAME=$(whiptail --title "HOST NAME" --nocancel  --inputbox "Hostname:" 12 35 3>&1 1>&2 2>&3)
whiptail --title "SET ROOT PASSWD" --infobox "\n WATTING PLEASE" 12 35
ROOT_PASSWD=$(whiptail --title "ROOT PASSWD" --nocancel --inputbox "Root password:" 12 35 3>&1 1>&2 2>&3)

DISK_NUM=$(whiptail --title "SELECT YOUR DISK" --menu "Select a Disk" 12 35 5 $(lsblk | grep disk | awk '{print(FNR,$1)}' | xargs) 3>&1 1>&2 2>&3)
DISK=$(lsblk | grep disk | awk '{print($1)}' | sed -n ${DISK_NUM}p)

#whiptail --title "REFLECTOR" --infobox "\n\n Wait a moment." 15 40
#reflector --country China --age 24 --sort rate --protocol https --save /etc/pacman.d/mirrorlist

mv /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlistbak
echo "Server = https://mirrors.tuna.tsinghua.edu.cn/archlinux/\$repo/os/\$arch
Server = https://mirrors.ustc.edu.cn/archlinux/\$repo/os/\$arch
Server = https://mirrors.bfsu.edu.cn/archlinux/\$repo/os/\$arch
Server = https://mirror.bjtu.edu.cn/disk3/archlinux/\$repo/os/\$arch" >> /etc/pacman.d/mirrorlist
pacman -Syy

parted -s /dev/${DISK} mklabel gpt 2> ./errorfile && parted -s /dev/${DISK} mkpart ESP fat32 2048s 2099199s 2> ./errorfile && parted -s /dev/${DISK} set 1 boot on 2> ./errorfile && parted -s /dev/${DISK} mkpart primary ext4 2099200s 100% 2> ./errorfile || funerror "partederror" 3
mkfs.fat -F32 /dev/${DISK}1 1> /dev/null 2> ./errorfile || funerror "mkfserror" 4
mkfs.ext4 /dev/${DISK}2 1> /dev/null 2> ./errorfile || funerror "mkfserror" 4
mount /dev/${DISK}2 /mnt && mkdir -p /mnt/boot/efi && mount /dev/${DISK}1 /mnt/boot/efi

clear

timedatectl set-ntp true

pacstrap /mnt base base-devel linux linux-firmware linux-headers bash-completion networkmanager vim nano git --noconfirm
genfstab -U /mnt >> /mnt/etc/fstab  --noconfirm

arch-chroot /mnt ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
arch-chroot /mnt hwclock --systohc
arch-chroot /mnt systemctl enable NetworkManager

arch-chroot /mnt pacman -S grub efibootmgr --noconfirm
arch-chroot /mnt grub-install --efi-directory=/boot/efi 
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg

arch-chroot /mnt chpasswd <<EOF
root:${ROOT_PASSWD}
EOF
sed "s/alias/export EDITOR=vim\nalias grep=\'grep --color=auto\'\nalias egrep=\'egrep --color=auto\'\nalias fgrep=\'fgrep --color=auto\'\nalias/g" /mnt/etc/skel/.bashrc > /mnt/root/.bashrc

echo "${HOST_NAME}" >> /mnt/etc/hostname
echo "127.0.0.1    localhost
::1    localhost
127.0.1.1    ${HOST_NAME}.localdomain    ${HOST_NAME}" >> /mnt/etc/hosts

tmp1=$(cat /proc/cpuinfo | grep name | grep Intel >> /dev/null)
if [ $? -eq 0 ]
then
    arch-chroot /mnt pacman -S intel-ucode --noconfirm 
	else
    arch-chroot /mnt pacman -S amd-ucode --noconfirm 
fi

mkdir /mnt/root/install
cp -r ./* /mnt/root/install/
umount /mnt/boot/efi
umount /mnt

whiptail --title "Reboot" --yesno "SUCCESSFUL!!!\n\nIf you want to do the following\nPlease Reboot and Run:\n    cd /root/install\n    chmod +x after.sh\n    ./after.sh\nReboot now?" 15 40 && reboot || exit 0
