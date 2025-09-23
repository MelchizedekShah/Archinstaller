#!/bin/bash

# funtion with all the variables that are handed over from 0-preinstall.sh
source /usr/local/share/Archinstaller/vars.sh

if [[ $cpufreq == y ]]; then
    git clone https://github.com/AdnanHodzic/auto-cpufreq.git
    cd auto-cpufreq && ./auto-cpufreq-installer
    cd ..
fi


if [[ de_choice != "SERVER" ]]; then
echo -ne "
-------------------------------------------------------------------------
                       Installing AUR Helper
-------------------------------------------------------------------------
"
# remove then paru dir
#
if [ -d /home/${username}/paru ]; then
    rm -rf /home/${username}/paru
fi

runuser -l ${username} <<'EOF'
    if ! command -v paru; then
        git clone https://aur.archlinux.org/paru.git ~/paru
        cd ~/paru
        makepkg -si --noconfirm
    fi
EOF
fi

echo -ne "
-------------------------------------------------------------------------
                            Networking
-------------------------------------------------------------------------

"

echo "Nog aan werken"
echo "ook prining support doen"
