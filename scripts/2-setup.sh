#!/bin/bash

# funtion with all the variables that are handed over from 0-preinstall.sh
source /usr/local/share/Archinstaller/vars.sh


echo -ne "
-------------------------------------------------------------------------
                        pacman configuration
-------------------------------------------------------------------------
"
sed -i 's/^#Color/Color/' /etc/pacman.conf
sed -i '/^Color$/a ILoveCandy' /etc/pacman.conf


echo -ne "
-------------------------------------------------------------------------
                            ucode
-------------------------------------------------------------------------
"

cpu_type=$(lscpu)
if grep -E "GenuineIntel" <<< ${cpu_type}; then
    echo "Installing Intel microcode"
    pacman -S --noconfirm --needed intel-ucode
    proc_ucode=intel-ucode.img
elif grep -E "AuthenticAMD" <<< ${cpu_type}; then
    echo "Installing AMD microcode"
    pacman -S --noconfirm --needed amd-ucode
    proc_ucode=amd-ucode.img
fi


echo -ne "
-------------------------------------------------------------------------
                    Installing Graphics Drivers
-------------------------------------------------------------------------
"

# if install nvidia install linux headers

gpu_type=$(lspci)
if grep -E "NVIDIA|GeForce" <<< ${gpu_type}; then
    echo "No support yet"
elif lspci | grep 'VGA' | grep -E "Radeon|AMD"; then
    pacman -S --noconfirm --needed vulkan-radeon mesa
elif grep -E "Integrated Graphics Controller" <<< ${gpu_type}; then
    pacman -S --noconfirm --needed vulkan-intel mesa
elif grep -E "Intel Corporation UHD" <<< ${gpu_type}; then
    pacman -S --noconfirm --needed vulkan-intel mesa
else
    echo "Not installing gpu drivers"
fi


echo -ne "
-------------------------------------------------------------------------
                    Installing Desktop Environment
-------------------------------------------------------------------------
"

case $de_choice in
    KDE)
        echo "Installing KDE Plasma..."
        pacman -S --noconfirm --needed plasma-meta sddm
        systemctl enable sddm
        echo "KDE Plasma installed successfully!"
        ;;
    GNOME)
         echo "Installing GNOME..."
         pacman -S --noconfirm --needed gnome gdm
         systemctl enable gdm
         echo "GNOME installed successfully!"
         ;;
    *)
        echo "Server or minimum setup"
        echo "Not installing DE"
        ;;

    esac


echo "Finished 2-setup.sh"
