#!/bin/bash

source /usr/local/share/Archinstaller/scripts/vars.sh

installpackage() {
    local pkgs="$@"
    while true; do
        if ! pacman -S --noconfirm --needed $pkgs; then
            echo "ERROR: Failed to install: $pkgs"
            echo "Retrying..."
        else
            echo "SUCCESS: Installed $pkgs"
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
cpu_type=$(lscpu)
if grep -E "GenuineIntel" <<< ${cpu_type}; then
    echo "Installing Intel microcode"
    installpackage intel-ucode
    proc_ucode=intel-ucode.img
elif grep -E "AuthenticAMD" <<< ${cpu_type}; then
    echo "Installing AMD microcode"
    installpackage amd-ucode
    proc_ucode=amd-ucode.img
fi

echo -ne "
-------------------------------------------------------------------------
                    Installing Graphics Drivers
-------------------------------------------------------------------------
"

if [[ $nvidia_install == "y" ]]; then
    echo "Installing NVIDIA proprietary drivers..."
    installpackage nvidia-dkms nvidia-utils linux-headers linux-lts-headers
elif grep -E "NVIDIA|GeForce" <<< $(lspci) && [[ $nvidia_install == "n" ]]; then
    echo "NVIDIA detected but user chose to skip - installing fallback drivers..."
    if lspci | grep 'VGA' | grep -E "Radeon|AMD"; then
        echo "Installing AMD drivers for dual graphics setup..."
        installpackage vulkan-radeon mesa
    elif lspci | grep 'VGA' | grep -E "Intel"; then
        echo "Installing Intel drivers for dual graphics setup..."
        installpackage vulkan-intel mesa
    fi
elif lspci | grep 'VGA' | grep -E "Radeon|AMD"; then
    echo "AMD GPU detected..."
    installpackage vulkan-radeon mesa
elif lspci | grep 'VGA' | grep -E "Intel"; then
    echo "Intel GPU detected..."
    installpackage vulkan-intel mesa
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
        installpackage plasma-meta sddm
        systemctl enable sddm
        echo "KDE Plasma installed successfully!"
        ;;
    GNOME)
        echo "Installing GNOME..."
        installpackage gnome gdm
        systemctl enable gdm
        echo "GNOME installed successfully!"
        ;;
    XFCE)
        echo "Installing XFCE..."
        installpackage xfce4 xfce4-goodies xorg \
            pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber \
            xfce4-pulseaudio-plugin pavucontrol \
            gst-plugin-pipewire alsa-utils network-manager-applet
        systemctl enable sddm
        echo "XFCE installed successfully!"
        ;;
    *)
        echo "Server or minimum setup"
        echo "Not installing DE"
        ;;
esac

echo "Finished 2-setup.sh"
