#! /bin/bash

funerror(){
    whiptail --title $1 --textbox errorfile 20 60
    exit $2
}

setfont /usr/share/kbd/consolefonts/iso01-12x22.psfu.gz
ping -c 4 www.baidu.com 1> /dev/null 2> ./errorfile || funerror "NetworkError!" 1

ADMIN_USER=$(whiptail --title "ADD_User" --nocancel --inputbox "User name:" 12 35 3>&1 1>&2 2>&3)
ADMIN_USER_PASSWD=$(whiptail --title "ADD_User" --nocancel --inputbox "User password:" 12 35 3>&1 1>&2 2>&3)

whiptail --title "ADD USER" --infobox "\n WAITTING PLEASE" 12 35
useradd --create-home ${ADMIN_USER}
chpasswd <<EOF
${ADMIN_USER}:${ADMIN_USER_PASSWD}
EOF
usermod -aG wheel,users,storage,power,lp,adm,optical ${ADMIN_USER}
sed -i "s/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/g" /etc/sudoers

echo "en_US.UTF-8 UTF-8
zh_CN.UTF-8 UTF-8" >> /etc/locale.gen
echo 'LANG=en_US.UTF-8' >> /etc/locale.conf
locale-gen &> /dev/null

# bash
sed -i "s/alias/export EDITOR=vim\nalias grep=\'grep --color=auto\'\nalias egrep=\'egrep --color=auto\'\nalias fgrep=\'fgrep --color=auto\'\nalias/g" /etc/skel/.bashrc
cp -r /etc/skel/. .

whiptail --title "Install Fonts" --infobox "\n WAITTING PLEASE" 12 35
pacman -S ttf-dejavu ttf-droid ttf-hack ttf-font-awesome otf-font-awesome ttf-lato ttf-liberation ttf-linux-libertine ttf-opensans ttf-roboto ttf-ubuntu-font-family ttf-hannom noto-fonts noto-fonts-extra noto-fonts-emoji noto-fonts-cjk adobe-source-code-pro-fonts adobe-source-sans-fonts adobe-source-serif-fonts adobe-source-han-sans-cn-fonts adobe-source-han-sans-hk-fonts adobe-source-han-sans-tw-fonts adobe-source-han-serif-cn-fonts wqy-zenhei wqy-microhei  --noconfirm 1> /dev/null 2> ./errorfile || funerror "pacmanerror" 2

whiptail --title "FreeType2" --infobox "\n Wait a moment, please." 12 35
sed -i "s/#export/export/g" /mnt/etc/profile.d/freetype2.sh

whiptail --title "Install Sound&Print Driver" --infobox "\n Waitting Please" 12 35
pacman -S alsa-utils pulseaudio pulseaudio-bluetooth cups --noconfirm 1> /dev/null 2> ./errorfile || funerror "InstallSound&PrintDriver" 2

installKde(){
    whiptail --title "Install Kde" --infobox "\n WAITTING PLEASE" 12 35
    pacman -S plasma dolphin konsole kdeconnect firefox chromium gwenview ntfs-3g ksystemlog ark kget kcalc kcolorchooser spectacle kate flameshot --noconfirm 1> /dev/null 2> ./errorfile || funerror "pacmanerror" 2
    systemctl enable sddm &> /dev/null
}
installXfce(){
    whiptail --title "Install Xfce" --infobox "\n WAITTING PLEASE" 12 35
    pacman -S xfce4 xfce4-goodies lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings network-manager-applet pavucontrol pulseaudio --noconfirm 1> /dev/null 2> ./errorfile || funerror "pacmanerror" 2
    systemctl enable lightdm &> /dev/null
}
installGnome(){
    whiptail --title "Install Gnome" --infobox "\n WAITTING PLEASE" 12 35
    pacman -S gnome --noconfirm 1> /dev/null 2> ./errorfile || funerror "pacmanerror" 2
    systemctl enable gdm &> /dev/null
}
installDeepin(){
    whiptail --title "Install Deepin" --infobox "\n WAITTING PLEASE" 12 35
    pacman -S deepin deepin-extra --noconfirm 1> /dev/null 2> ./errorfile || funerror "pacmanerror" 2
    systemctl enable lightdm &> /dev/null
    sed -i "s/#greeter-session=example-gtk-gnome/greeter-session=lightdm-deepin-greeter/g" /etc/lightdm/lightdm.conf
}

DESKTOP_ENV=$(whiptail --title "SELECT DESKTP" --menu "SELECT YOUR DESKTP" 12 40 5 1 no-desktop 2 XFCE 3 KDE 4 GNOME 5 Deepin 3>&1 1>&2 2>&3)
if [ ${DESKTOP_ENV} != "1" ]
then
    whiptail --title "Install GPU DRIVE" --infobox "\n WAITTING PLEASE" 12 35
    NVIDIA=0
    INTEL=0
    tmp1=$(lspci | grep -i vga | grep -i nvidia >> /dev/null)
    if [ $? -eq 0 ]
    then
        NVIDIA=1
        pacman -S nvidia --noconfirm 1> /dev/null 2> ./errorfile || funerror "pacmanerror" 2
    fi
    tmp1=$(lspci | grep -i vga | grep -i intel >> /dev/null)
    if [ $? -eq 0 ]
    then
        INTEL=1
        pacman -S mesa vulkan-intel libva-intel-driver intel-media-driver --noconfirm 1> /dev/null 2> ./errorfile || funerror "pacmanerror" 2
    fi
    if [ ${NVIDIA} -eq 1 -a ${INTEL} -eq 1 ]
    then
        pacman -S nvidia-prime --noconfirm 1> /dev/null 2> ./errorfile || funerror "pacmanerror" 2
    fi
    whiptail --title "Install XORG" --infobox "\n WAITTING PLEASE" 12 35
    pacman -S xorg --noconfirm 1> /dev/null 2> ./errorfile || funerror "pacmanerror" 2

    case ${DESKTOP_ENV} in
        "2") installXfce
        ;;
        "3") installKde
        ;;
        "4") installGnome
        ;;
        "5") installDeepin
        ;;
    esac
fi
whiptail --title "Install XORG" --infobox "\n WAITTING PLEASE" 12 35
pacman -S xorg xorg-xinit dolphin konsole firefox chromium gwenview ntfs-3g ksystemlog ark kcalc kcolorchooser spectacle kate flameshot alacritty --noconfirm 1> /dev/null 2> ./errorfile || funerror "pacmanerror" 2

whiptail --title "ADD ARCHLINUXCN" --infobox "\n WAITTING PLEASE" 12 35
pacman -S haveged --noconfirm 1> /dev/null 2> ./errorfile || funerror "pacmanerror" 2
systemctl enable haveged &> /dev/null
rm -rf /etc/pacman.d/gnupg &> /dev/null
pacman-key --init &> /dev/null
pacman-key --populate archlinux &> /dev/null
echo "[archlinuxcn]
Server = https://mirrors.tuna.tsinghua.edu.cn/archlinuxcn/\$arch" >> /etc/pacman.conf
pacman -Syu &> /dev/null
pacman -S archlinuxcn-keyring --noconfirm 1> /dev/null 2> ./errorfile || funerror "pacmanerror" 2

whiptail --title "Empty Cache" --infobox "wait a minutes" 12 35
pacman -Scc --noconfirm 1> /dev/null 2> ./errorfile || funerror "Empty Cache" 2
cp -r ./install ../home/${ADMIN_USER}/
# rm -rf ../install

whiptail --title "Thanks" --yesno "Install Archlinux Successful\nThanks for using this script\nMy blog: https://blog.jinjiang.fun\nReboot now?" 15 40 && reboot || exit 0
