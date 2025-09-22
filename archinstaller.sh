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

( bash $SCRIPTS_DIR/0-preinstall.sh )|& tee 0-preinstall.log

mkdir -p /mnt/usr/local/share/Archinstaller
cp -r "$SCRIPT_DIR"/* /mnt/usr/local/share/Archinstaller/
chmod +x /mnt/usr/local/share/Archinstaller/scripts/*

( arch-chroot /mnt /usr/local/share/Archinstaller/scripts/1-preinstall.sh )|& tee 1-preinstall.log
( arch-chroot /mnt /usr/local/share/Archinstaller/scripts/2-setup.sh )|& tee 2-setup.log

# unmount all the mount points
umount -R /mnt

echo -ne "
-------------------------------------------------------------------------
                    Installation finished!
-------------------------------------------------------------------------
"
echo "Please reboot your Installation"
