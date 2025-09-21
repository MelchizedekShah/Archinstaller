#!/bin/bash


echo -ne "
-------------------------------------------------------------------------
                        Adding a user
-------------------------------------------------------------------------
"

read -p "Enter your desired username: " USERNAME
Useradd –m –G wheel –s /bin/bash ${USERNAME}



echo -ne "
-------------------------------------------------------------------------
                        pacman configuration
-------------------------------------------------------------------------
"
sed -i 's/^#Color/Color/' /etc/pacman.conf
sed -i '/^Color$/a ILoveCandy' /etc/pacman.conf

echo -ne "
-------------------------------------------------------------------------
                        pacman configuration
-------------------------------------------------------------------------
"
git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si
cd ..
