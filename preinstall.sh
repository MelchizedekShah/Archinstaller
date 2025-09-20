#!/bin/bash

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

-------------------------------------------------------------------------
                    Checking EFI firmware platform size
-------------------------------------------------------------------------
"

if [[ -f /sys/firmware/efi/fw_platform_size ]]; then
    EFI_SIZE=$(cat /sys/firmware/efi/fw_platform_size)
    echo "EFI platform size detected: $EFI_SIZE-bit"

    if [[ $EFI_SIZE != "64" ]]; then
        echo "Not supported exiting..."
        exit
    fi
else
    # BIOS system detected
    echo "Error: BIOS/Legacy boot detected"
    echo "This installer requires 64-bit EFI firmware"
    exit
fi

echo -ne "
-------------------------------------------------------------------------
                    Updating the system clock
-------------------------------------------------------------------------
"
timedatectl set-ntp true
timedatectl



echo -ne "
-------------------------------------------------------------------------
                    Formating the disk
-------------------------------------------------------------------------
"
echo "Available disks:"
lsblk -d -o NAME,SIZE,MODEL

while [ true ]; do
    read -p "Enter disk name (e.g., sda): " DISK_NAME
    DISK="/dev/$DISK_NAME"
    if [[ -b "$DISK" ]]; then
        break
    else
        echo "Invalid disk. Try again."
    fi
done

while [ true ]; do
    echo "Selected DISK: $DISK"
    read -p "Continue (y/n) " confirm
    if [[ $confirm == "y" || $confirm == "Y" ]]; then
        break
    elif [[ $confirm == "n" || $confirm == "N" ]]; then
        exit
    else
        echo "Enter a valid input"
    fi
done

umount -A --recursive /mnt
sgdisk -Z ${DISK}
sgdisk -a 2048 -o ${DISK}

sgdisk -n 1::+3G --typecode=1:ef00 --change-name=1:'EFIBOOT'
sgdisk -n 2::-0 --typecode=2:8300 --change-name=2:'ROOT' ${DISK}
partprobe ${DISK}
lsblk
