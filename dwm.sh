#! /bin/bash
#
# clone dwm dmenu st (https://suckless.org)
#

cp -r dwm.sh ../

sudo rm -rf install

cp /etc/X11/xinit/xinitrc .xinitrc
sed -i "/geometry/d" .xinitrc && sed -i "s/twm &/\n\n\nexec dwm/g" .xinitrc

mkdir app
git clone https://git.suckless.org/dwm app/dwm && git clone https://git.suckless.org/dwm app/dmenu && git clone https://git.suckless.org/dwm app/st &> /dev/null

cd app/dwm && sudo make clean install
cd ../dmenu && sudo make clean install
cd ../st && sudo make clean install

cd ../ && ls
