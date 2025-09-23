#!/bin/bash

# funtion with all the variables that are handed over from 0-preinstall.sh
source /usr/local/share/Archinstaller/vars.sh

if [[ $cpufreq == y ]]; then
    git clone https://github.com/AdnanHodzic/auto-cpufreq.git
    cd auto-cpufreq && ./auto-cpufreq-installer
    cd ..
fi

echo -ne "
-------------------------------------------------------------------------
                       Installing AUR Helper
-------------------------------------------------------------------------

runuser -l ${username} <<'EOF'
    set -e
    if ! command -v paru; then
        git clone https://aur.archlinux.org/paru.git ~/paru
        cd ~/paru
        makepkg -si --noconfirm
    fi
EOF


"

echo -ne "
-------------------------------------------------------------------------
                            Networking
-------------------------------------------------------------------------

"

echo "Nog aan werken"
echo "ook prining support doen"



echo "path: ${pwd}"
