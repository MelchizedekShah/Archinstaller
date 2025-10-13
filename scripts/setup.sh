#!/bin/bash

# nog op werken
#source config.sh



# This script only gets information from the user, this information will be stored and used in the other scripts


echo -ne "
-------------------------------------------------------------------------
                Setting up username and password
-------------------------------------------------------------------------
"

echo "Please select key board layout from this list"
echo ""

options=(us by ca cf cz de dk es et fa fi fr gr hu il it lt lv mk nl no pl ro ru sg ua uk)

for choice in ${options[@]}; do
    echo -n "$choice "
done

echo ""
echo ""
read -p "Enter your key boards layout: " key_layout

found_key=n

while true; do
    for choice in ${options[@]}; do
        if [[ $key_layout == $choice ]]; then
            found_key=y
            break
            fi
    done
    if [[ $found_key == y ]]; then
        echo ""
        echo "Your selected keyboard layout: ${key_layout}"
        break
    else
        echo "ERROR - enter a valid input"
        read -p "Enter your key boards layout: " key_layout
    fi

done

# load the keyboard layout
loadkeys ${key_layout}

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

echo ""

# Set a user password
while true; do
    read -s -p "Please enter user password: " password
    echo ""
    if (( ${#password} < 2 )); then
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

echo ""

# Set a root password
while true; do
    read -s -p "Please enter root password: " root_password
    echo ""
    if (( ${#password} < 2 )); then
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

timezone="$(curl --fail https://ipapi.co/timezone)"

read -p "Is this your timezone? ${timezone} (y/n) " anwser
while true; do
    if [[ $anwser == "y" || $anwser == "Y" ]]; then
        break
    elif [[ $anwser == "n" || $anwser == "N" ]]; then
        break
    else
        echo "Enter a valid input"
    fi
done

if [[ $anwser == "n" || $anwser == "N" ]]; then

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
fi


echo -ne "
-------------------------------------------------------------------------
                        Chose your DE or server
-------------------------------------------------------------------------
"
echo "Please select a option:"
echo "1) KDE Plasma"
echo "2) GNOME"
echo "3) XFCE"
echo "4) Server"
echo "5) Minimal"
echo ""
echo "Default is Minimal (press Enter for default)"
read -p "Enter your choice [1-5]: " de_choice

# Set default if empty
if [[ -z "$de_choice" ]]; then
    de_choice=5
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
        echo "XFCE setup"
        de_choice=XFCE
        ;;
    4)
        echo "Server setup"
        de_choice=SERVER
        ;;
    5)
        echo "Minimal setup"
        de_choice=MIN
        ;;
    *)
        echo "Invalid choice. Setting up minimal setup"
        de_choice=MIN
        ;;

esac

echo -ne "
-------------------------------------------------------------------------
                           Hibernation
-------------------------------------------------------------------------
"
while true; do
read -p "Will you hibernate your computer? (y/n): " hibernate
if [[ $hibernate == "y" || $hibernate == "Y" ]]; then
    hibernate="YES"
    break
elif [[ $hibernate == "n" || $hibernate == "N" ]]; then
    hibernate="NO"
    break
else
    echo "Enter a vaild input"
fi
done

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

gpu_type=$(lspci)
if grep -E "NVIDIA|GeForce" <<< ${gpu_type}; then
    echo "NVIDIA GPU DETECTED"

    while true; do
        read -p "Install proprietary NVIDIA drivers? (y/n): " nvidia_choice

        if [[ $nvidia_choice == "y" || $nvidia_choice == "Y" ]]; then
            echo "Setting up NVIDIA proprietary drivers..."
            nvidia_install=y
            break
        elif [[ $nvidia_choice == "n" || $nvidia_choice == "N" ]]; then
            echo "Skipping NVIDIA drivers (using open-source/integrated graphics)"
            nvidia_install=n
            break
        else
            echo "Enter a valid input"
        fi
    done
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

 # Dual boot support setup
if [[ $platform == "EFI" ]]; then
    #echo "Partitions on $DISK:"
    while true; do
        read -p "Are you dual booting with Windows? (y/n): " dualboot
        if [[ $dualboot == "y" || $dualboot == "Y" ]]; then
            $dualboot="y"
        elif [[ $dualboot == "n" || $dualboot == "N" ]]; then
            $dualboot="n"
        else
            echo "Enter a valid option"
        fi
    done
fi

echo -ne "
-------------------------------------------------------------------------
                          LUKS Setup
-------------------------------------------------------------------------
"

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

if [[ $disk_encrypt == "y" ]]; then

    # Set a luks password
    while true; do
        read -s -p "Please enter LUKS password: " luks_password
        echo ""

        if (( ${#password} < 2 )); then
            continue
        fi
        read -s -p "Confirm password: " password_confirm
        if [[ "$luks_password" == "$password_confirm" ]]; then
            echo ""
            echo "LUKS password setup success"
            break
        else
            echo ""
            echo "LUKS passwords do not match. Try again."
        fi
    done
fi

clear
echo -ne "
-------------------------------------------------------------------------
                        INSTALLATION CONFORMATION
-------------------------------------------------------------------------
"
sleep 1
echo -ne "
Please review your installation configuration:

Firmware Type:        $platform
Target Disk:          $DISK
Dualboot:             $(if [[ $dualboot == "y" ]]; then echo "YES"; else echo "NO"; fi)
Disk Encryption:      $(if [[ $disk_encrypt == "y" ]]; then echo "ENABLED (LUKS)"; else echo "DISABLED"; fi)
Hostname:             $name_of_machine
Timezone:             $timezone
Username:             $username
Root Password:        $(printf '%*s' ${#root_password} '' | tr ' ' '*')
User Password:        $(printf '%*s' ${#password} '' | tr ' ' '*')
Installation Type:    $de_choice
Swap size:            $(if [[ $hibernate == "YES" ]]; then echo "2X RAM size"; else echo "2-4G"; fi)

"
$(if [[ $de_choice == "SERVER" ]]; then
echo "Server Filesystem:    $server_file"
fi)
# end confirmation nex the disk wipe

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

cat > scripts/vars.sh << EOF
# Archinstaller configuration variables

# Disk & system information
DISK=$DISK
dualboot=$dualboot
platform=$platform
disk_encrypt=$disk_encrypt
partition1=$partition1
server_file=$server_file
hibernate=$hibernate

# User & hostname creation
username=$username
root_password=$root_password
password=$password
luks_password=$luks_password
name_of_machine=$name_of_machine
timezone=$timezone
key_layout=$key_layout

# DE choice
de_choice=$de_choice

# GPU GRAPHICS
nvidia_install=$nvidia_install

EOF



# moet in 0 gaan
