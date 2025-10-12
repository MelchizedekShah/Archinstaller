#!/bin/bash

# funtion with all the variables that are handed over from 0-preinstall.sh
source /usr/local/share/Archinstaller/scripts/vars.sh


installpackage() {
    local pkgs="$@"
    while true; do
        if ! pacman -S --noconfirm --needed $pkgs; then
            echo "ERROR: Failed to install: $pkgs"
            echo "Retrying..."
        else
            echo "SUCCESS: Installed $pkgs"
            break
        fi
    done
}

echo -ne "
-------------------------------------------------------------------------
                        Desktop customizations
-------------------------------------------------------------------------
"

if [[ $de_choice == "XFCE" ]]; then
    echo "XFCE setup..."

    # overwrite the xinitrc file
    cat > /home/${username}/.xinitrc << EOF
#!/bin/bash
exec startxfce4
EOF
    chmod +x /home/${username}/.xinitrc

    # append to bash_profile if not already present
    if ! grep -q "exec startx" /home/${username}/.bash_profile 2>/dev/null; then
        cat >> /home/${username}/.bash_profile << EOF
if [[ -z \$DISPLAY ]] && [[ \$(tty) == /dev/tty1 ]]; then
    exec startx
fi
EOF
    fi
fi


if [[ $de_choice == "KDE" ]]; then
    installpackage flatpak-kcm plasma-meta dolphin konsole kwalletmanager filelight \
        kdeconnect partitionmanager flatpak-kcm papirus-icon-theme
fi
echo -ne "
-------------------------------------------------------------------------
                            Networking
-------------------------------------------------------------------------

"
echo "Nog aan werken"
echo "ook prining support doen"
