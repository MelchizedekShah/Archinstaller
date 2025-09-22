#!/bin/bash

# funtion with all the variables that are handed over from 0-preinstall.sh
source /usr/local/share/Archinstaller/vars.sh

# bios setup function
biossetup() {

# mkinitcpio
if [[ $DISK_ENCRYPT = 'y' ]]; then
    sed -i 's/^HOOKS=(.*)/HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block encrypt lvm2 filesystems fsck)/' /etc/mkinitcpio.conf
else
    sed -i 's/^HOOKS=(.*)/HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block lvm2 filesystems fsck)/' /etc/mkinitcpio.conf
fi

# installing grub
grub-install --target=i386-pc ${partition1}
grub-mkconfig -o /boot/grub/grub.cfg

}

# efi setup function
efisetup() {

# mkinitcpio setup
if [[ $DISK_ENCRYPT = 'y' ]]; then
    sed -i 's/^HOOKS=(.*)/HOOKS=(base systemd autodetect microcode modconf kms keyboard sd-vconsole block sd-encrypt lvm2 filesystems fsck)/' /etc/mkinitcpio.conf
else
    sed -i 's/^HOOKS=(.*)/HOOKS=(base systemd autodetect microcode modconf kms keyboard sd-vconsole block lvm2 filesystems fsck)/' /etc/mkinitcpio.conf
fi

# .preset files
if [[ $de_choice != "SERVER" ]]
cat > /etc/mkinitcpio.d/linux.preset <<'EOF'
# mkinitcpio preset file for the 'linux' package
ALL_config="/etc/mkinitcpio.conf"
ALL_kver="/boot/vmlinuz-linux"

PRESETS=('default')

default_uki="/efi/EFI/Linux/arch-linux.efi"
EOF
fi

cat > /etc/mkinitcpio.d/linux-lts.preset <<'EOF'
# mkinitcpio preset file for the 'linux-lts' package
ALL_config="/etc/mkinitcpio.conf"
ALL_kver="/boot/vmlinuz-linux-lts"

PRESETS=('default')

default_uki="/efi/EFI/Linux/arch-linux-lts.efi"
EOF

# installing boot loader
bootctl install
cat > /efi/loader/loader.conf <<'EOF'
default arch-linux.efi
timeout 5
console-mode auto
editor no
EOF

systemctl enable systemd-boot-update.service
}

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

-------------------------------------------------------------------------
                        Password setup
-------------------------------------------------------------------------
"

if [[ $(whoami) = "root" ]]; then
    # use chpasswd to enter $USERNAME:$password
    echo "$(whoami):$root_password" | chpasswd
    echo "$(whoami) password set"

    echo "$username:$password" | chpasswd
    echo "$username password set"
fi

echo -ne "
-------------------------------------------------------------------------
                            Time setup
-------------------------------------------------------------------------
"

ln -sf /usr/share/zoneinfo/${timezone} /etc/localtime
hwclock --systohc

echo -ne "
-------------------------------------------------------------------------
                        Localization
-------------------------------------------------------------------------
"

sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf

# installing tty font package
pacman -S terminus-font --noconfirm --needed
echo "KEYMAP=us" >> /etc/vconsole.conf && echo "FONT=ter-132b" >> /etc/vconsole.conf


echo -ne "
-------------------------------------------------------------------------
                        Network configuration
-------------------------------------------------------------------------
"

# setting up host name
echo "${name_of_machine}" >> /etc/hostname
systemctl enable NetworkManager


echo -ne "
------------------------------------------------------------------------------------------------
 Configure mkinitcpio & Configure the kernel cmdline & .preset file & Installing the bootloader
------------------------------------------------------------------------------------------------
"
if [[ $PLATFORM == "EFI" ]]; then
    efisetup
    echo "rd.luks.name=${LUKS_UUID}=cryptlvm root=/dev/archvolume/root rw" > /etc/kernel/cmdline
elif [[ $PLATFORM == "BIOS" ]]; then
    biossetup
    echo "cryptdevice=UUID=${LUKS_UUID}:cryptlvm root=/dev/archvolume/root" >
fi

echo -ne "
-------------------------------------------------------------------------
                            mkinitcpio
-------------------------------------------------------------------------
"

mkinitcpio -P



# Finished 1-preinstall.sh
