#!/bin/bash

if [[ $de_choice != 3 ]]; then

    echo -ne "
        -------------------------------------------------------------------------
                        Installing Auto-cpufreq
        -------------------------------------------------------------------------
        "

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
