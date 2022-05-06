#! /bin/bash

funerror(){
    whiptail --title $1 --textbox errorfile 20 60
    exit $2
}

setfont /usr/share/kbd/consolefonts/iso01-12x22.psfu.gz
whiptail --title "FBI WARNING" --yesno "FIRST YOU SHOULD PARTITION THE DISK." 12 35 || exit 0
DISK_NUM=$(whiptail --title "Select a Disk" --menu "Select a Disk" 12 35 5 $(lsblk | grep disk | awk '{print(FNR,$1)}' | xargs) 3>&1 1>&2 2>&3)
DISK=$(lsblk | grep disk | awk '{print($1)}' | sed -n ${DISK_NUM}p)
HOST_NAME=$(whiptail --title "HOST NAME" --nocancel  --inputbox "Hostname:" 12 35 3>&1 1>&2 2>&3)
ROOT_PASSWD=$(whiptail --title "ROOT PASSWD" --nocancel --inputbox "Root password:" 12 35 3>&1 1>&2 2>&3)
ping -c 4 www.baidu.com 1> /dev/null 2> ./errorfile || funerror "NetworkError!" 1

systemctl stop reflector.service
#whiptail --title "REFLECTOR" --infobox "\n\n Wait a moment." 15 40
#reflector --country China --age 24 --sort rate --protocol https --save /etc/pacman.d/mirrorlist

mv /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlistbak
echo "Server = https://mirrors.tuna.tsinghua.edu.cn/archlinux/\$repo/os/\$arch
Server = https://mirrors.ustc.edu.cn/archlinux/\$repo/os/\$arch
Server = https://mirrors.bfsu.edu.cn/archlinux/\$repo/os/\$arch
Server = https://mirror.bjtu.edu.cn/disk3/archlinux/\$repo/os/\$arch" >> /etc/pacman.d/mirrorlist
pacman -Syy --noconfirm 1> /dev/null 2> ./errorfile || funerror "UPDATE" 2

whiptail --title "DISK" --infobox "\n DISK PARTITION." 12 35
parted -s /dev/${DISK} mklabel gpt 2> ./errorfile && parted -s /dev/${DISK} mkpart ESP fat32 1M 1025M 2> ./errorfile && parted -s /dev/${DISK} set 1 boot on 2> ./errorfile && parted -s /dev/${DISK} mkpart primary ext4 1025M 100% 2> ./errorfile || funerror "partederror" 3
mkfs.fat -F32 /dev/${DISK}1 1> /dev/null 2> ./errorfile || funerror "mkfserror" 4
mkfs.ext4 /dev/${DISK}2 1> /dev/null 2> ./errorfile || funerror "mkfserror" 4
mount /dev/${DISK}2 /mnt && mkdir -p /mnt/boot/efi && mount /dev/${DISK}1 /mnt/boot/efi

timedatectl set-ntp true

whiptail --title "Install System" --infobox "\n Waitting Please" 12 35
pacstrap /mnt base base-devel linux linux-firmware linux-headers bash-completion networkmanager vim nano git --noconfirm 1> /dev/null 2> ./errorfile || funerror "InstallSystem1" 2
genfstab -U /mnt >> /mnt/etc/fstab  --noconfirm 1> /dev/null 2> ./errorfile || funerror "InstallSystem2" 2

whiptail --title "Env Set" --infobox "\n Waitting Please" 12 35
arch-chroot /mnt ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
arch-chroot /mnt hwclock --systohc
arch-chroot /mnt systemctl enable NetworkManager &> /dev/null

whiptail --title "Install GURB" --infobox "Installing and Configuring GRUB, please wait" 12 35
arch-chroot /mnt pacman -S grub efibootmgr --noconfirm 1> /dev/null 2> ./errorfile || funerror "pacmanerror" 2
arch-chroot /mnt grub-install --efi-directory=/boot/efi 1> /dev/null 2> ./errorfile || funerror "grub-installerror" 8
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg 1> /dev/null 2> ./errorfile || funerror "grub-mkconfigerror" 9

whiptail --title "ADD ROOT PWD" --infobox "\n Waitting Please" 12 35
arch-chroot /mnt chpasswd <<EOF
root:${ROOT_PASSWD}
EOF
sed "s/alias/export EDITOR=vim\nalias grep=\'grep --color=auto\'\nalias egrep=\'egrep --color=auto\'\nalias fgrep=\'fgrep --color=auto\'\nalias/g" /mnt/etc/skel/.bashrc > /mnt/root/.bashrc

whiptail --title "HOST NAME" --infobox "\n Waitting Please" 12 35
echo "${HOST_NAME}" >> /mnt/etc/hostname
echo "127.0.0.1    localhost
::1    localhost
127.0.1.1    ${HOST_NAME}.localdomain    ${HOST_NAME}" >> /mnt/etc/hosts

tmp1=$(cat /proc/cpuinfo | grep name | grep Intel >> /dev/null)
if [ $? -eq 0 ]
then
    whiptail --title "Installing" --infobox "Installing intel-ucode, please wait" 12 35
    arch-chroot /mnt pacman -S intel-ucode --noconfirm 1> /dev/null 2> ./errorfile || funerror "pacmanerror" 2
else
    whiptail --title "Installing" --infobox "Installing amd-ucode, please wait" 12 35
    arch-chroot /mnt pacman -S amd-ucode --noconfirm 1> /dev/null 2> ./errorfile || funerror "pacmanerror" 2
fi

mkdir /mnt/root/install
cp -r ./* /mnt/root/install/
umount /mnt/boot/efi
umount /mnt

whiptail --title "Reboot" --yesno "Install Archlinux Successful\nIf you want to do the following\nPlease Reboot and Run:\n    cd /root/install\n    chmod +x after.sh\n    ./after.sh\nReboot now?" 15 40 && reboot || exit 0
