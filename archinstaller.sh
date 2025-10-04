#!/bin/bash

# Find the name of the folder the scripts are in
set -a
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
SCRIPTS_DIR="$SCRIPT_DIR/scripts"
set +a
chmod +x ${SCRIPTS_DIR}/*

clear

echo -ne "
-------------------------------------------------------------------------
    _             _     _           _        _ _
   / \   _ __ ___| |__ (_)_ __  ___| |_ __ _| | | ___ _ __
  / _ \ | '__/ __| '_ \| | '_ \/ __| __/ _  | | |/ _ \ '__|
 / ___ \| | | (__| | | | | | | \__ \ || (_| | | |  __/ |
/_/   \_\_|  \___|_| |_|_|_| |_|___/\__\__,_|_|_|\___|_|
-------------------------------------------------------------------------
                    Automated Arch Linux Installer
-------------------------------------------------------------------------
"

sleep 1

( bash $SCRIPTS_DIR/setup.sh )|& tee setup.log
( bash $SCRIPTS_DIR/0-preinstall.sh )|& tee 0-preinstall.log


( arch-chroot /mnt /usr/local/share/Archinstaller/scripts/1-preinstall.sh )|& tee 1-preinstall.log
( arch-chroot /mnt /usr/local/share/Archinstaller/scripts/2-setup.sh )|& tee 2-setup.log
( arch-chroot /mnt /usr/local/share/Archinstaller/scripts/3-user.sh )|& tee 3-user.log

# Copy everything again after the installation
# To get the complete log files on the host
cp -r "$SCRIPT_DIR"/* /mnt/usr/local/share/Archinstaller/

# unmount all the mount points
umount -R /mnt 2>/dev/null

clear

echo -ne "
-------------------------------------------------------------------------
    _             _     _           _        _ _
   / \   _ __ ___| |__ (_)_ __  ___| |_ __ _| | | ___ _ __
  / _ \ | '__/ __| '_ \| | '_ \/ __| __/ _  | | |/ _ \ '__|
 / ___ \| | | (__| | | | | | | \__ \ || (_| | | |  __/ |
/_/   \_\_|  \___|_| |_|_|_| |_|___/\__\__,_|_|_|\___|_|
-------------------------------------------------------------------------
                    Automated Arch Linux Installer
-------------------------------------------------------------------------
"

sleep 1

echo -ne "
-------------------------------------------------------------------------
                    Installation finished!
-------------------------------------------------------------------------
"
echo "Please reboot your Installation"
