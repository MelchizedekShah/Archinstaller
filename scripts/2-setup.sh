#!/bin/bash


echo -ne "
-------------------------------------------------------------------------
                        Adding a user
-------------------------------------------------------------------------
"

while true
	do
		read -p "Please enter username:" username
		if [[ "${username,,}" =~ ^[a-z_]([a-z0-9_-]{0,31}|[a-z0-9_-]{0,30}\$)$ ]]
		then
			break
		fi
		echo "Incorrect username."
	done

useradd -m -G wheel -s /bin/bash ${username}
passwd ${username}
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers


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

gpu_type=$(lspci)
if grep -E "NVIDIA|GeForce" <<< ${gpu_type}; then
    echo "No support yet"
elif lspci | grep 'VGA' | grep -E "Radeon|AMD"; then
    pacman -S --noconfirm --needed vulkan-radeon mesa
elif grep -E "Integrated Graphics Controller" <<< ${gpu_type}; then
    pacman -S --noconfirm --needed vulkan-intel mesa
elif grep -E "Intel Corporation UHD" <<< ${gpu_type}; then
    pacman -S --noconfirm --needed vulkan-intel mesa
fi


echo -ne "
-------------------------------------------------------------------------
                    Installing Desktop Environment
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
        #echo "Installing KDE Plasma..."
        #pacman -S --noconfirm --needed plasma-meta sddm
        #systemctl enable sddm
        #echo "KDE Plasma installed successfully!"
        de_choice=KDE
        ;;
    2)
         #echo "Installing GNOME..."
         #pacman -S --noconfirm --needed gnome gdm
         #systemctl enable gdm
         #echo "GNOME installed successfully!"
         de_choice=GNOME
         ;;
    3)
        echo "Server setup"
        de_choice=SERVER
        ;;
    4)
        echo "Minimal setup"
        de_choice=MIN
    *)
        #echo "Invalid choice. Installing Minimal setup"
        #pacman -S --noconfirm --needed plasma-meta sddm
        #systemctl enable sddm
        #echo "KDE Plasma installed successfully!"
        de_choice=MIN
        ;;

esac
