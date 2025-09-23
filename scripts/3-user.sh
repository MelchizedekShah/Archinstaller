#!/bin/bash

# funtion with all the variables that are handed over from 0-preinstall.sh
source /usr/local/share/Archinstaller/vars.sh

if [[ $cpufreq == y ]]; then
    git clone https://github.com/AdnanHodzic/auto-cpufreq.git
    cd auto-cpufreq && ./auto-cpufreq-installer
    cd ..
fi

-------------------------------------------------------------------------
                            Networking
-------------------------------------------------------------------------
"

echo "Nog aan werken"
echo "ook prining support doen"
