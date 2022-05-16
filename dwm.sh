#! /bin/bash
#
# install dwm for admin user
#

echo "GTK_IM_MODULE=fcitx
QT_IM_MODULE=fcitx
XMODIFIERS=@im=fcitx
INPUT_METHOD=fcitx
SDL_IM_MODULE=fcitx" >> ~/.pam_environment

cp -r /etc/skel/.ba* ~/

mkdir -p ~/.config/alacritty && cp /usr/share/doc/alacritty/example/alacritty.yml ~/.config/alacritty/
sed -i "s/#font:/font:/g" ~/.config/alacritty/alcritty.yml && sed -i "s/#size: 11\.0/size: 13\.0/g" ~/.config/alacritty/alacritty.yml

cp /etc/X11/xinit/xinitrc ~/.xinitrc
sed -i "/geometry/d" ~/.xinitrc && sed -i "s/twm \&/\n\nfeh --bg-fill --randomize \/usr\/share\/backgrounds\/archlinux\/*\n\npicom \&\n\n\nexec dwm/g" ~/.xinitrc

cd adwm/dwm && make clean && sudo make clean install && make clean
cd ../dmenu && make clean && sudo make clean install && make clean
cd ../st && make clean && sudo make clean install && make clean


