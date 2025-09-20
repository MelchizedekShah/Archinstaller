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

sgdisk -n 1::+3G --typecode=1:ef00 --change-name=1:'EFIBOOT' ${DISK}
sgdisk -n 2::-0 --typecode=2:8300 --change-name=2:'ROOT' ${DISK}
partprobe ${DISK}


# Calculating sizes for lvm
RAM_GB=$(free -m | awk '/^Mem:/ {printf "%.0f", $2/1024}')
DISK_SIZE_RAW=$(lsblk -d -n -o SIZE $DISK)
DISK_SIZE=$(echo $DISK_SIZE_RAW | sed 's/G//' | awk '{printf "%.0f", $1}')
SWAP_SIZE=$((RAM_GB * 2))
ROOT_SIZE=$(((DISK_SIZE - SWAP_SIZE) * 40 / 100))
echo "Swap size: ${SWAP_SIZE}"
echo "Root size: ${ROOT_SIZE}"

if [[ "${DISK}" =~ "nvme" || "${DISK}" =~ "mmcblk" ]]; then
    partition1=${DISK}p1
    partition2=${DISK}p2
else
    partition1=${DISK}1
    partition2=${DISK}2
fi


cryptsetup luksFormat ${partition2}
cryptsetup open ${partition2} cryptlvm
pvcreate /dev/mapper/cryptlvm
vgcreate archvolume /dev/mapper/cryptlvm
lvcreate -L ${SWAP_SIZE}G -n swap archvolume
lvcreate -L ${ROOT_SIZE}G -n root archvolume
lvcreate -l 100%FREE -n home archvolume


echo -ne "
-------------------------------------------------------------------------
                    Creating filesystems
-------------------------------------------------------------------------
"

mkfs.ext4 /dev/mapper/archvolume-root
mkfs.ext4 /dev/mapper/archvolume-home
mkswap /dev/mapper/archvolume-swap
lvreduce -L -256M --resizefs archvolume/home
mount /dev/mapper/archvolume-root /mnt
mkdir /mnt/home
mount /dev/mapper/archvolume-home /mnt/home
swapon /dev/mapper/archvolume-swap
mkfs.fat -F32 ${partition1}
mkdir /mnt/efi
mount ${partition1} /mnt/efi


while [ true ]; do
    lsblk
    read -p "Continue (y): " anwser
    if [[ $anwser == "y" || $anwser == "Y" ]]; then
        break
    fi
done
