#!/bin/bash

calculatelvm() {
    # Calculating sizes for lvm
    RAM_GB=$(free -m | awk '/^Mem:/ {printf "%.0f", $2/1024}')
    DISK_SIZE_RAW=$(lsblk -d -n -o SIZE $DISK)
    DISK_SIZE=$(echo $DISK_SIZE_RAW | sed 's/G//' | awk '{printf "%.0f", $1}')
    SWAP_SIZE=$((RAM_GB * 2))
    ROOT_SIZE=$(((DISK_SIZE - SWAP_SIZE) * 40 / 100))
    echo "Swap size: ${SWAP_SIZE}G"
    echo "Root size: ${ROOT_SIZE}G"
}

set_partition_names() {
    # Set partition names based on disk type
    if [[ "${DISK}" =~ "nvme" || "${DISK}" =~ "mmcblk" ]]; then
        partition1=${DISK}p1
        partition2=${DISK}p2
    else
        partition1=${DISK}1
        partition2=${DISK}2
    fi
}

setup_encryption() {
    if [[ $disk_encrypt == "y" ]]; then
        echo "Setting up LUKS encryption..."
        # Loop for encryption setup with error handling
        while true; do
            if cryptsetup luksFormat ${partition2}; then
                break
            else
                echo "Encryption setup failed. Retrying..."
                read -p "Press Enter to retry or Ctrl+C to exit..."
            fi
        done

        while true; do
            if cryptsetup open ${partition2} cryptlvm; then
                break
            else
                echo "Failed to open encrypted partition. Retrying..."
                read -p "Press Enter to retry or Ctrl+C to exit..."
            fi
        done

        LVM_DEVICE="/dev/mapper/cryptlvm"
    else
        echo "Setting up without encryption..."
        LVM_DEVICE="${partition2}"
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

    # Confirmation step
    while true; do
        lsblk
        read -p "Continue (y): " answer
        if [[ $answer == "y" || $answer == "Y" ]]; then
            break
        fi
    done
}

biossetup() {
    calculatelvm
    set_partition_names
    setup_encryption
    setup_lvm
    create_filesystems
    mount_common_filesystems

    if [[ $de_choice == "SERVER" ]]; then
        if [[ $server_file == "XFS" ]]; then
            mkfs.xfs ${partition1}
            mkdir /mnt/boot
            mount ${partition1} /mnt/boot
        else
            mkfs.ext4 ${partition1}
            mkdir /mnt/boot
            mount ${partition1} /mnt/boot
        fi
    else
        # Setup boot partition with ext4
        mkfs.ext4 ${partition1}
        mkdir /mnt/boot
        mount ${partition1} /mnt/boot
    fi

    # Confirmation step
      while true; do
          lsblk
          read -p "Continue (y): " answer
          if [[ $answer == "y" || $answer == "Y" ]]; then
              break
          fi
      done
}


# Getting user info for later
# set username

echo -ne "
-------------------------------------------------------------------------
                Setting up username and password
-------------------------------------------------------------------------
"

while true; do
	read -p "Please enter username: " username
	if [[ "${username,,}" =~ ^[a-z_]([a-z0-9_-]{0,31}|[a-z0-9_-]{0,30}\$)$ ]]; then
		break
	fi
	    echo "Incorrect username."
done

# Set a user password
while true; do
    read -s -p "Please enter user password: " password
    echo ""
    if [[ $password < 2 ]]; then
        continue
    fi
    read -s -p "Confirm password: " password_confirm
    if [[ "$password" == "$password_confirm" ]]; then
        echo ""
        echo "Password setup success"
        break
    else
        echo ""
        echo "User passwords do not match. Try again."
    fi
done

# Set a root password
while true; do
    read -s -p "Please enter root password: " root_password
    echo ""
    if [[ $root_password < 2 ]]; then
           continue
    fi
    read -s -p "Confirm password: " password_confirm
    if [[ "$root_password" == "$password_confirm" ]]; then
        echo ""
        echo "Password root setup success"
        break
    else
        echo ""
        echo "Root passwords do not match. Try again."
    fi
done

echo -ne "
-------------------------------------------------------------------------
                        Setting hostname
-------------------------------------------------------------------------
"
while true; do
	read -p "Please name your machine: " name_of_machine
	if [[ "${name_of_machine,,}" =~ ^[a-z][a-z0-9_.-]{0,62}[a-z0-9]$ ]]; then
		break
	fi
done

echo -ne "
-------------------------------------------------------------------------
                        Chose your timezone
-------------------------------------------------------------------------
"
echo "Available regions:"
ls /usr/share/zoneinfo/ | tr '\n' ' ' | sort
echo ""

while true; do
    read -p "Enter your region (e.g., America, Europe, Asia): " region
    echo ""
    if [[ $region < 2 ]]; then
        continue
    fi
    if [[ -d "/usr/share/zoneinfo/$region" ]]; then
        break
    else
        echo "Invalid region. Please try again."
    fi
done

echo ""
echo "Available cities/zones in $region:"
ls "/usr/share/zoneinfo/$region" | tr '\n' ' ' | sort
echo ""

while true; do
    read -p "Enter your city/zone (e.g., New_York, London, Tokyo): " city
    if [[ -f "/usr/share/zoneinfo/$region/$city" ]]; then
        timezone="$region/$city"
        break
    else
        echo "Invalid city/zone. Please try again."
    fi
done
echo "Timezone selected: $timezone"

echo -ne "
-------------------------------------------------------------------------
                        Chose your DE or server
-------------------------------------------------------------------------
"
echo "Please select a option:"
echo "1) KDE Plasma"
echo "2) GNOME"
echo "3) Server"
echo "4) Minimal"
echo ""
echo "Default is KDE (press Enter for default)"
read -p "Enter your choice [1-4]: " de_choice

# Set default if empty
if [[ -z "$de_choice" ]]; then
    de_choice=1
fi

case $de_choice in
    1)
        echo "KDE Plasma setup"
        de_choice=KDE
        ;;
    2)
        echo "GNOME setup"
        de_choice=GNOME
        ;;
    3)
        echo "Server setup"
        de_choice=SERVER
        ;;
    4)
        echo "Minimal setup"
        de_choice=MIN
        ;;
    *)
        echo "Invalid choice. Setting up minimal setup"
        de_choice=MIN
        ;;

esac

# filesystem choice for server setup
if [[ $de_choice == "SERVER" ]]; then
echo -ne "
-------------------------------------------------------------------------
                              Server filesystem
-------------------------------------------------------------------------
"
    echo "XFS: large files, big data, or servers where performance and scalability matter more than shrinkability."
    echo "EXT4: general-purpose servers, small web apps, and situations where simplicity and reliability matter."
    echo "Please select a option:"
    echo "1) XFS"
    echo "2) EXT4"
    echo "Default is XFS (press Enter for default)"
    read -p "Enter your choice [1-2]: " server_file

    # Set default if empty
    if [[ -z "$server_file" ]]; then
        server_file=1
    fi

    case $server_file in
        1)
            echo "Setting up XFS filesytem"
            server_file=XFS
            ;;
        2)
            echo "Setting up EXT4 filesytem"
            server_file=EXT4
            ;;
        *)
            echo "Setting up default: XFS filesytem"
            server_file=XFS
            ;;
    esac
fi


echo -ne "
-------------------------------------------------------------------------
                    Checking firmware platform
-------------------------------------------------------------------------
"

if [[ -f /sys/firmware/efi/fw_platform_size ]]; then
    EFI_SIZE=$(cat /sys/firmware/efi/fw_platform_size)
    echo "EFI platform size detected: $EFI_SIZE-bit"
    if [[ $EFI_SIZE != "64" ]]; then
        echo "Not supported exiting..."
        exit 1
    fi
    platform=EFI
else
    echo "BIOS firmware detected"
    platform=BIOS
fi

echo -ne "
-------------------------------------------------------------------------
                    Formatting the disk
-------------------------------------------------------------------------
"

echo "Available disks:"
lsblk -d -o NAME,SIZE,MODEL

while true; do
    read -p "Enter disk name (e.g., sda): " DISK_NAME
    DISK="/dev/$DISK_NAME"
    if [[ -b "$DISK" ]]; then
        break
    else
        echo "Invalid disk. Try again."
    fi
done

while true; do
    read -p "Do you want to encrypt your system? (y/n): " ENCRYPT
    if [[ $ENCRYPT == "y" || $ENCRYPT == "Y" ]]; then
        disk_encrypt=y
        break
    elif [[ $ENCRYPT == "n" || $ENCRYPT == "N" ]]; then
        disk_encrypt=n
        break
    else
        echo "Enter a valid input"
    fi
done

echo "***********************************************************"
echo " WARNING: You are about to completely WIPE ${DISK}!"
echo " All data on this disk will be LOST forever."
echo "***********************************************************"
while true; do
    read -p "Continue (y/n) " confirm
    if [[ $confirm == "y" || $confirm == "Y" ]]; then
        break
    elif [[ $confirm == "n" || $confirm == "N" ]]; then
        exit 0
    else
        echo "Enter a valid input"
    fi
done

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
    sgdisk -n 1::+1G --typecode=1:ef02 --change-name=1:'BIOSBOOT' ${DISK}
    sgdisk -n 2::-0 --typecode=2:8300 --change-name=2:'ROOT' ${DISK}
    sgdisk -A 1:set:2 ${DISK}
    partprobe ${DISK}
    biossetup
else
    echo "ERROR: Unknown platform, exiting..."
    exit 1
fi

# done with disk setup


# Store variables for later use
echo -ne "
-------------------------------------------------------------------------
                    Storing configuration variables
-------------------------------------------------------------------------
"

# Set partition names again for UUID collection and for bios partition collection
if [[ "${DISK}" =~ "nvme" || "${DISK}" =~ "mmcblk" ]]; then
    partition1=${DISK}p1
    partition2=${DISK}p2
else
    partition1=${DISK}1
    partition2=${DISK}2
fi

# Create vars.sh file
mkdir -p /mnt/usr/local/share/Archinstaller
cat > /mnt/usr/local/share/Archinstaller/vars.sh << EOF
# Archinstaller configuration variables

# Disk & system information
DISK=$DISK
PLATFORM=$platform
DISK_ENCRYPT=$disk_encrypt
RAM_GB=$RAM_GB
SWAP_SIZE=$SWAP_SIZE
ROOT_SIZE=$ROOT_SIZE
partition1=$partition1
server_file=$server_file

# User & hostname creation
username=$username
root_password=$root_password
password=$password
name_of_machine=$name_of_machine
timezone=$timezone

# DE choice
de_choice=$de_choice


EOF

# Store UUIDs based on setup
if [[ $disk_encrypt == "y" ]]; then
    LUKS_UUID=$(blkid -s UUID -o value "$partition2")
    ROOT_UUID=$(blkid -s UUID -o value /dev/mapper/archvolume-root)
    echo "LUKS_UUID=$LUKS_UUID" >> /mnt/usr/local/share/Archinstaller/vars.sh
    echo "ROOT_UUID=$ROOT_UUID" >> /mnt/usr/local/share/Archinstaller/vars.sh
    echo "Stored LUKS UUID: $LUKS_UUID"
    echo "Stored ROOT UUID: $ROOT_UUID"
fi

echo "Configuration saved to /mnt/usr/local/share/Archinstaller/vars.sh"


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
    packages="base base-devel bash linux linux-firmware linux-lts gdisk lvm2 networkmanager vim man-db man-pages texinfo git"
elif [[ $de_choice == SERVER ]]; then
    if [[ $server_file == "XFS" ]]; then
        packages="xfsprogs base base-devel bash linux-firmware linux-lts gdisk lvm2 networkmanager vim man-db man-pages texinfo git"
    else
        packages="base base-devel bash linux-firmware linux-lts gdisk lvm2 networkmanager vim man-db man-pages texinfo git"
    fi
fi

while true; do
    if ! pacstrap -K /mnt ${packages} --noconfirm --needed; then
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
    echo "Fixing EFI mount options in fstab..."
    sed -i '/\/efi/ s/fmask=[0-9]\{4\}/fmask=0137/; s/dmask=[0-9]\{4\}/dmask=0027/' /mnt/etc/fstab
else
    echo "Check bios fstab... still in development"
fi


echo "Finished 0-preinstall.sh"
