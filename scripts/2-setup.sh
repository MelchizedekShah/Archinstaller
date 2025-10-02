#!/bin/bash

# funtion with all the variables that are handed over from 0-preinstall.sh
source /usr/local/share/Archinstaller/vars.sh


installpackage() {
    while true; do
        if ! pacman -S --noconfirm --needed ${packages}; then
            echo "ERROR: Package installation failed"
            echo "Try again.."
        else
            echo "Succes"
            break
        fi
    done
}

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
# The mkinitcpio is done here

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

# In the chrooted script - check user's previous choice
if [[ $nvidia_install == "y" ]]; then
    echo "Installing NVIDIA proprietary drivers..."
    # Add NVIDIA driver installation here
    pacman -S --noconfirm --needed nvidia-dkms nvidia-utils linux-headers linux-lts-headers
elif grep -E "NVIDIA|GeForce" <<< $(lspci) && [[ $nvidia_install == "n" ]]; then
    echo "NVIDIA detected but user chose to skip - installing fallback drivers..."
    # For dual graphics, install drivers for the OTHER GPU
    if lspci | grep 'VGA' | grep -E "Radeon|AMD"; then
        echo "Installing AMD drivers for dual graphics setup..."
        pacman -S --noconfirm --needed vulkan-radeon mesa
    elif lspci | grep 'VGA' | grep -E "Intel"; then
        echo "Installing Intel drivers for dual graphics setup..."
        pacman -S --noconfirm --needed vulkan-intel mesa
    fi
elif lspci | grep 'VGA' | grep -E "Radeon|AMD"; then
    echo "AMD GPU detected..."
    pacman -S --noconfirm --needed vulkan-radeon mesa
elif lspci | grep 'VGA' | grep -E "Intel"; then
    echo "Intel GPU detected..."
    pacman -S --noconfirm --needed vulkan-intel mesa
else
    echo "No recognized GPU found"
fi

echo -ne "
-------------------------------------------------------------------------
                    Installing Desktop Environment
-------------------------------------------------------------------------
"

case $de_choice in
    KDE)
        echo "Installing KDE Plasma..."
        packages="plasma-meta sddm"
        installpackage
        systemctl enable sddm
        echo "KDE Plasma installed successfully!"
        ;;
    GNOME)
         echo "Installing GNOME..."
         packages="gnome gdm"
         installpackage
         systemctl enable gdm
         echo "GNOME installed successfully!"
         ;;
    XFCE)
        echo "Installing XFCE..."
        packages="xfce4 xfce4-goodies xorg \
        pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber \
        xfce4-pulseaudio-plugin pavucontrol \
        gst-plugin-pipewire alsa-utils network-manager-applet"

        installpackage
        systemctl enable sddm
        echo "XFCE installed successfully!"
        ;;
    *)
        echo "Server or minimum setup"
        echo "Not installing DE"
        ;;

    esac






echo "Finished 2-setup.sh"
