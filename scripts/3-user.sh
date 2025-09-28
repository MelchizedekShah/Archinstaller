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

    # edit the xinitrc file
    cat > /home/${username}/.xinitrc << "EOF"
    #!/bin/bash
    exec startxfce4
    EOF
    chmod +x /home/${username}/.xinitrc

    # edit the bash profile file
    if ! grep -q "exec startx" /home/${username}/.bash_profile 2>/dev/null; then
    cat >> /home/${username}/.bash_profile << "EOF"
    if [[ -z $DISPLAY ]] && [[ $(tty) == /dev/tty1 ]]; then
        exec startx
    fi
    EOF
    fi
fi


echo -ne "
-------------------------------------------------------------------------
                            Networking
-------------------------------------------------------------------------

"
echo "Nog aan werken"
echo "ook prining support doen"
