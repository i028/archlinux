#! /bin/bash

funerror(){
    whiptail --title $1 --textbox errorfile 20 60
    exit $2
}

#setfont /usr/share/kbd/consolefonts/iso01-12x22.psfu.gz
#ping -c 4 www.baidu.com 1> /dev/null 2> ./errorfile || funerror "NetworkError!" 1

ADMIN_USER=$(whiptail --title "ADD USER" --nocancel --inputbox "User name:" 12 35 3>&1 1>&2 2>&3)
ADMIN_USER_PASSWD=$(whiptail --title "ADD USER" --nocancel --inputbox "User password:" 12 35 3>&1 1>&2 2>&3)
DESKTOP_ENV=$(whiptail --title "SELECT DESKTP" --menu "SELECT YOUR DESKTP" 15 35 6 1 NONE 2 DWM 3 KDE 4 GNOME 5 DEEPIN 3>&1 1>&2 2>&3)

useradd --create-home ${ADMIN_USER}
chpasswd <<EOF
${ADMIN_USER}:${ADMIN_USER_PASSWD}
EOF
usermod -aG wheel,users,storage,power,lp,adm,optical ${ADMIN_USER}
sed -i "s/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/g" /etc/sudoers

clear

echo "en_US.UTF-8 UTF-8
zh_CN.UTF-8 UTF-8" >> /etc/locale.gen
echo 'LANG=en_US.UTF-8' >> /etc/locale.conf
locale-gen

# bash
sed -i "s/alias/export EDITOR=vim\nalias grep=\'grep --color=auto\'\nalias egrep=\'egrep --color=auto\'\nalias fgrep=\'fgrep --color=auto\'\nalias/g" /etc/skel/.bashrc
cp -r /etc/skel/.bash* ~/

sed -i "s/#export/export/g" /etc/profile.d/freetype2.sh

echo "========  Font  ========"
pacman -S ttf-dejavu ttf-droid noto-fonts noto-fonts-extra noto-fonts-emoji noto-fonts-cjk adobe-source-code-pro-fonts wqy-zenhei wqy-microhei alsa-utils pulseaudio pulseaudio-bluetooth cups --noconfirm

echo "========  Xorg  ========"
pacman -S xorg xorg-xinit --noconfirm

installDWM(){
    echo "========  App && Fcitx5  ========"
    pacman -S dolphin konsole firefox nitrogen gwenview ueberzug numlockx ntfs-3g ksystemlog ark kcalc kcolorchooser kate flameshot alacritty feh rofi picom rxvt-unicode krita archlinux-wallpaper fcitx5-im fcitx5-chinese-addons fcitx5-rime fcitx5-material-color fcitx5-nord --noconfirm 1> ./errorfile || funerror "pacmanerror" 2
		echo "GTK_IM_MODULE	DEFAULT=fcitx5
QT_IM_MODULE	DEFAULT=fcitx5
XMODIFIERS	DEFAULT=@im=fcitx5
INPUT_METHOD	DEFAULT=fcitx5
SDL_IM_MODULE	DEFAULT=fcitx5" >> ~/.pam_environment
    #sed -i "s/#font:/font:/g" /usr/share/doc/alacritty/example/alcritty.yml && sed -i "s/#size: 11/size: 13/g" /usr/share/doc/alacritty/example/alacritty.yml
    mkdir -p ~/.config/alacritty && cp /usr/share/doc/alacritty/example/alacritty.yml ~/.config/alacritty/
    #sed -i "s/shadow = true/shadow = false/g" /etc/xdg/picom.conf
    #sed -i "s/# opacity-rule = \[\]/opacity-rule = \[\"90:class_g = \'dwm\'\",\"90:class_g = \'Alacritty\'\",\"90:class_g = \'st-256colors\'\",\]/g" /etc/xdg/picom.conf
    mkdir -p ~/.config/picom && cp /etc/xdg/picom.conf ~/.config/picom/
    git clone https://github.com/i028/adwm
		cp -r adwm ../
		cd adwm && bash install.sh
}
installKde(){
    pacman -S plasma dolphin konsole kdeconnect firefox chromium gwenview ntfs-3g ksystemlog ark kget kcalc kcolorchooser spectacle kate flameshot --noconfirm
    systemctl enable sddm
}
installXfce(){
    pacman -S xfce4 xfce4-goodies lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings network-manager-applet pavucontrol pulseaudio --noconfirm
    systemctl enable lightdm
}
installGnome(){
    pacman -S gnome --noconfirm
    systemctl enable gdm
    echo 'LANG=en_US.UTF-8' >> /etc/locale.conf && locale-gen
}
installDeepin(){
    pacman -S deepin deepin-extra --noconfirm
    systemctl enable lightdm
    sed -i "s/#greeter-session=example-gtk-gnome/greeter-session=lightdm-deepin-greeter/g" /etc/lightdm/lightdm.conf
}

if [ ${DESKTOP_ENV} != "1" ]
then
    NVIDIA=0
    INTEL=0
    tmp1=$(lspci | grep -i vga | grep -i nvidia >> /dev/null)
    if [ $? -eq 0 ]
    then
        NVIDIA=1
        pacman -S nvidia --noconfirm
    fi
    tmp1=$(lspci | grep -i vga | grep -i intel >> /dev/null)
    if [ $? -eq 0 ]
    then
        INTEL=1
        pacman -S mesa vulkan-intel libva-intel-driver intel-media-driver --noconfirm
    fi
    if [ ${NVIDIA} -eq 1 -a ${INTEL} -eq 1 ]
    then
        pacman -S nvidia-prime --noconfirm
    fi

    case ${DESKTOP_ENV} in
        "2") installDWM
        ;;
        "3") installKde
        ;;
        "4") installGnome
        ;;
        "5") installDeepin
        ;;
    esac
fi


pacman -S haveged --noconfirm
systemctl enable haveged
rm -rf /etc/pacman.d/gnupg
pacman-key --init
pacman-key --populate archlinux
echo "[archlinuxcn]
Server = https://mirrors.tuna.tsinghua.edu.cn/archlinuxcn/\$arch" >> /etc/pacman.conf
pacman -Syu
pacman -S archlinuxcn-keyring --noconfirm

#whiptail --title "Empty Cache" --infobox "wait a minutes" 12 35
#pacman -Scc --noconfirm 1> /dev/null 2> ./errorfile || funerror "Empty Cache" 2
cp -r ../install /home/${ADMIN_USER}/
# rm -rf ../install

#whiptail --title "SUCCESSFUL" --yesno "SUCCESSFUL!!!\n\nScript from {MurphyWZhu/archlinux}\nThanks!\n\nReboot now?" 15 40 && reboot || exit 0
