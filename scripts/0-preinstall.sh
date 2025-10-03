#!/bin/bash

source scripts/vars.sh

calculatelvm() {
    # Calculating sizes for lvm
    RAM_GB=$(free -m | awk '/^Mem:/ {printf "%.0f", $2/1024}')
    DISK_SIZE_RAW=$(lsblk -d -n -o SIZE $DISK)
    DISK_SIZE=$(echo $DISK_SIZE_RAW | sed 's/G//' | awk '{printf "%.0f", $1}')
    if [[ $hibernate == "YES" ]]; then
        SWAP_SIZE=$((RAM_GB * 2))
    elif [[ $DISK_SIZE < 40 ]]; then
        SWAP_SIZE=2
    else
        SWAP_SIZE=4
    fi
    ROOT_SIZE=$(((DISK_SIZE - SWAP_SIZE) * 40 / 100))
    echo "Swap size: ${SWAP_SIZE}G"
    echo "Root size: ${ROOT_SIZE}G"
}

set_partition_names() {
    # Set partition names again for UUID collection and for bios partition collection
    if [[ "${DISK}" =~ "nvme" || "${DISK}" =~ "mmcblk" ]]; then
        partition1=${DISK}p1
        partition2=${DISK}p2
        if [[ $platform == "BIOS" ]]; then
            partition3=${DISK}p3
        fi

    else
        partition1=${DISK}1
        partition2=${DISK}2
        if [[ $platform == "BIOS" ]]; then
            partition3=${DISK}3
        fi
    fi

}

setup_encryption() {
    if [[ $disk_encrypt == "y" ]]; then
        echo "Setting up LUKS encryption..."

        #  which partition to encrypt based on platform
        if [[ $platform == "BIOS" ]]; then
            ENCRYPT_PARTITION=${partition3}
        else
            ENCRYPT_PARTITION=${partition2}
        fi

        while true; do
            if echo -n "${luks_password}" | cryptsetup -y -v luksFormat ${ENCRYPT_PARTITION} -; then
                break
            else
                echo "Encryption setup failed. Retrying..."
                read -p "Press Enter to retry or Ctrl+C to exit..."
            fi
        done

        # Open the encrypted partition
        while true; do
            if echo -n "${luks_password}" | cryptsetup open ${ENCRYPT_PARTITION} cryptlvm -; then
                break
            else
                echo "Failed to open encrypted partition. Retrying..."
                read -p "Press Enter to retry or Ctrl+C to exit..."
            fi
        done

        LVM_DEVICE="/dev/mapper/cryptlvm"
    else
        echo "Setting up without encryption..."
        # Set LVM device based on platform
        if [[ $platform == "BIOS" ]]; then
            LVM_DEVICE="${partition3}"
        else
            LVM_DEVICE="${partition2}"
        fi
    fi
}

setup_lvm() {
    # Create LVM setup
    pvcreate $LVM_DEVICE
    vgcreate archvolume $LVM_DEVICE
    lvcreate -L ${SWAP_SIZE}G -n swap archvolume
    lvcreate -L ${ROOT_SIZE}G -n root archvolume
    lvcreate -l 100%FREE -n home archvolume
}

create_filesystems() {
    echo -ne "
-------------------------------------------------------------------------
                    Creating filesystems
-------------------------------------------------------------------------
"
    # Check if the setup is server with Xfs else use default setup ext4
    if [[ $de_choice == "SERVER" ]]; then
        if [[ $server_file == "XFS" ]]; then
            mkfs.xfs /dev/mapper/archvolume-root
            mkfs.xfs /dev/mapper/archvolume-home
            mkswap /dev/mapper/archvolume-swap
        else
            mkfs.ext4 /dev/mapper/archvolume-root
            mkfs.ext4 /dev/mapper/archvolume-home
            mkswap /dev/mapper/archvolume-swap
            # Reduce home partition by 256M to leave some free space
            lvreduce -L -256M --resizefs archvolume/home
        fi
    else
        # Create filesystems
        mkfs.ext4 /dev/mapper/archvolume-root
        mkfs.ext4 /dev/mapper/archvolume-home
        mkswap /dev/mapper/archvolume-swap
        # Reduce home partition by 256M to leave some free space
        lvreduce -L -256M --resizefs archvolume/home
    fi
}

mount_common_filesystems() {
    # Mount the filesystems
    mount /dev/mapper/archvolume-root /mnt
    mkdir /mnt/home
    mount /dev/mapper/archvolume-home /mnt/home
    swapon /dev/mapper/archvolume-swap
}

# funtion that formats the disk for a EFI firmware system
efisetup() {
    calculatelvm
    set_partition_names
    setup_encryption
    setup_lvm
    create_filesystems
    mount_common_filesystems

    # Setup EFI partition
    mkfs.fat -F32 ${partition1}
    mkdir /mnt/efi
    mount ${partition1} /mnt/efi

 }

# funtion that formats the disk for a BIOS firmware system
biossetup() {
    calculatelvm
    set_partition_names
    setup_encryption
    setup_lvm
    create_filesystems
    mount_common_filesystems

    # Setup boot partition
    #mkfs.ext4 ${partition1}
    #mkdir /mnt/boot
    #mount ${partition1} /mnt/boot

    # Setup BIOS partition
    mkfs.fat -F32 ${partition1}
    mkdir /mnt/boot
    mount ${partition1} /mnt/boot

}

# Getting rid of everything
umount -A --recursive /mnt 2>/dev/null
sgdisk -Z ${DISK}
sgdisk -a 2048 -o ${DISK}

# Create partitions based on platform
if [[ $platform == "EFI" ]]; then
    sgdisk -n 1::+3G --typecode=1:ef00 --change-name=1:'EFIBOOT' ${DISK}
    sgdisk -n 2::-0 --typecode=2:8300 --change-name=2:'ROOT' ${DISK}
    partprobe ${DISK}
    efisetup
elif [[ $platform == "BIOS" ]]; then
    sgdisk -n 1::+1G --typecode=1:8300 --change-name=1:'BOOT' ${DISK} # partition1
    sgdisk -n 2::+2M --typecode=2:ef02 --change-name=2:'BIOSBOOT' ${DISK}
    sgdisk -n 3::-0 --typecode=3:8300 --change-name=3:'ROOT' ${DISK}
    sgdisk -A 1:set:2 ${DISK}
    partprobe ${DISK}
    biossetup
else
    echo "ERROR: Unknown platform, exiting..."
    exit 1
fi

# If something did not go right you need to be able to rerun the script
# Confirmation step
while true; do
    lsblk
    read -p "Continue (y/n): " answer
    if [[ $answer == "y" || $answer == "Y" ]]; then
        break
    elif [[ $answer == "n" || $answer == "N" ]]; then
        echo "Cleaning up and cancelling installation..."
        # Unmount all mounted filesystems
        umount -R /mnt 2>/dev/null
        # Deactivate swap
        swapoff /dev/mapper/archvolume-swap 2>/dev/null
        # Remove LVM volumes
        lvremove -f archvolume/swap 2>/dev/null
        lvremove -f archvolume/root 2>/dev/null
        lvremove -f archvolume/home 2>/dev/null
        # Remove volume group
        vgremove -f archvolume 2>/dev/null
        # Remove physical volume
        pvremove ${LVM_DEVICE} 2>/dev/null
        # Close encrypted device if it exists
        if [[ $disk_encrypt == "y" ]]; then
            cryptsetup close cryptlvm 2>/dev/null
        fi
        # Wipe partition table
        sgdisk -Z ${DISK} 2>/dev/null

        clear
        echo "========================================="
        echo "     Installation Cancelled"
        echo "========================================="
        echo "Disk has been cleaned up."
        echo "You can safely rerun the script."
        sleep 2
        exit 0
    fi
done

# done with disk setup

mkdir -p /mnt/usr/local/share/Archinstaller
cp -r "$SCRIPT_DIR"/* /mnt/usr/local/share/Archinstaller/
chmod +x /mnt/usr/local/share/Archinstaller/scripts/*

# Store UUIDs based on setup
if [[ $disk_encrypt == "y" ]]; then
    if [[ $platform == "BIOS" ]]; then
        LUKS_UUID=$(blkid -s UUID -o value "$partition3")
    else
        LUKS_UUID=$(blkid -s UUID -o value "$partition2")
    fi
    echo "LUKS_UUID=$LUKS_UUID" >> /mnt/usr/local/share/Archinstaller/scripts/vars.sh
    echo "Stored LUKS UUID: $LUKS_UUID"
fi

echo "UUID saved to /mnt/usr/local/share/Archinstaller/vars.sh"

echo -ne "
-------------------------------------------------------------------------
                    Updating the system clock
-------------------------------------------------------------------------
"
timedatectl set-ntp true
timedatectl

echo -ne "
-------------------------------------------------------------------------
                    Selecting the mirrors
-------------------------------------------------------------------------
"

echo "Updating mirrors with reflector..."
    if ! reflector --verbose --latest 10 --protocol https --sort rate --save /etc/pacman.d/mirrorlist; then
        echo "Warning: Reflector failed, using existing mirrors"
        echo "You may want to manually update /etc/pacman.d/mirrorlist later"
    fi

echo -ne "
-------------------------------------------------------------------------
                    Installing essential packages
-------------------------------------------------------------------------
"

if [[ $de_choice != SERVER ]]; then
    packages="base base-devel bash linux linux-firmware linux-lts gdisk lvm2 networkmanager vim man-db man-pages texinfo"
elif [[ $de_choice == SERVER ]]; then
    if [[ $server_file == "XFS" ]]; then
        packages="xfsprogs base bash linux-firmware linux-lts gdisk lvm2 networkmanager vim man-db man-pages texinfo"
    else
        packages="base bash linux-firmware linux-lts gdisk lvm2 networkmanager vim man-db man-pages texinfo"
    fi
fi

# Add EFI boot manager if needed
if [[ $platform == "EFI" ]]; then
    packages+=" efibootmgr"
fi

while true; do
    if ! pacstrap -K /mnt --noconfirm --needed ${packages}; then
        echo "ERROR: Package installation failed"
        echo "Try again.."
    else
        echo "Succes"
        break
    fi
done

echo -ne "
-------------------------------------------------------------------------
                    Configuring the system
-------------------------------------------------------------------------
"

genfstab -U /mnt >> /mnt/etc/fstab

if [[ $platform == "EFI" ]]; then
    echo "Fixing EFI mount boot options in fstab..."
    sed -i '/\/efi/ s/fmask=[0-9]\{4\}/fmask=0137/; s/dmask=[0-9]\{4\}/dmask=0027/' /mnt/etc/fstab

elif [[ $platform == "BIOS" ]]; then
    echo "Fixing BIOS mount boot options in fstab..."
    sed -i '/\/boot/ s/fmask=[0-9]\{4\}/fmask=0137/; s/dmask=[0-9]\{4\}/dmask=0027/' /mnt/etc/fstab
else
    echo "error.. no valid platform"
fi

echo "Finished 0-preinstall.sh"
