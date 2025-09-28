#!/bin/bash

# funtion with all the variables that are handed over from 0-preinstall.sh
source /usr/local/share/Archinstaller/vars.sh


echo -ne "
-------------------------------------------------------------------------
                        Desktop customizations
-------------------------------------------------------------------------
"

if [[ $de_choice == "XFCE" ]]; then
    echo "XFCE setup..."
    sudo pacman -S --needed --noconfirm xorg-xinit
    echo "exec startxfce4" > /home/${username}/.xinitrc


    #customizations
fi


echo -ne "
-------------------------------------------------------------------------
                            Networking
-------------------------------------------------------------------------

"
echo "Nog aan werken"
echo "ook prining support doen"
