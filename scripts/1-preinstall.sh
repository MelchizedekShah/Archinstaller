#!/bin/bash

# funtion with all the variables that are handed over from 0-preinstall.sh
source /usr/local/share/Archinstaller/vars.sh

# bios setup function
biossetup() {

# mkinitcpio
if [[ $DISK_ENCRYPT = 'y' ]]; then
    pacman -S cryptsetup --noconfirm --needed
    sed -i 's/^HOOKS=(.*)/HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block encrypt lvm2 filesystems fsck)/' /etc/mkinitcpio.conf
else
    sed -i 's/^HOOKS=(.*)/HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block lvm2 filesystems fsck)/' /etc/mkinitcpio.conf
fi


# .preset files
if [[ $de_choice != "SERVER" ]]; then
cat > /etc/mkinitcpio.d/linux.preset <<'EOF'
# mkinitcpio preset file for the 'linux' package
ALL_config="/etc/mkinitcpio.conf"
ALL_kver="/boot/vmlinuz-linux"

PRESETS=('default')

default_image="/boot/initramfs-linux.img"
EOF

cat > /etc/mkinitcpio.d/linux-lts.preset <<'EOF'
# mkinitcpio preset file for the 'linux-lts' package
ALL_config="/etc/mkinitcpio.conf"
ALL_kver="/boot/vmlinuz-linux-lts"

PRESETS=('default')

default_image="/boot/initramfs-linux-lts.img"
EOF

# servers .preset files (only lts kernel)
else
cat > /etc/mkinitcpio.d/linux-lts.preset <<'EOF'
ALL_config="/etc/mkinitcpio.conf"
ALL_kver="/boot/vmlinuz-linux-lts"

PRESETS=('default' 'fallback')

default_image="/boot/initramfs-linux-lts.img"

fallback_image="/boot/initramfs-linux-lts-fallback.img"
fallback_options="-S autodetect"
EOF
fi

# installing grub
pacman -S grub --noconfirm --needed
grub-install --target=i386-pc ${DISK}
grub-mkconfig -o /boot/grub/grub.cfg

}

# efi setup function
efisetup() {

# mkinitcpio setup
if [[ $DISK_ENCRYPT = 'y' ]]; then
    pacman -S cryptsetup --noconfirm --needed
    sed -i 's/^HOOKS=(.*)/HOOKS=(base systemd autodetect microcode modconf kms keyboard sd-vconsole block sd-encrypt lvm2 filesystems fsck)/' /etc/mkinitcpio.conf
else
    sed -i 's/^HOOKS=(.*)/HOOKS=(base systemd autodetect microcode modconf kms keyboard sd-vconsole block lvm2 filesystems fsck)/' /etc/mkinitcpio.conf
fi

# .preset files
if [[ $de_choice != "SERVER" ]]; then
cat > /etc/mkinitcpio.d/linux.preset <<'EOF'
# mkinitcpio preset file for the 'linux' package
ALL_config="/etc/mkinitcpio.conf"
ALL_kver="/boot/vmlinuz-linux"

PRESETS=('default')

default_uki="/efi/EFI/Linux/arch-linux.efi"
EOF

cat > /etc/mkinitcpio.d/linux-lts.preset <<'EOF'
# mkinitcpio preset file for the 'linux-lts' package
ALL_config="/etc/mkinitcpio.conf"
ALL_kver="/boot/vmlinuz-linux-lts"

PRESETS=('default')

default_uki="/efi/EFI/Linux/arch-linux-lts.efi"
EOF
else
cat > /etc/mkinitcpio.d/linux-lts.preset <<'EOF'
ALL_config="/etc/mkinitcpio.conf"
ALL_kver="/boot/vmlinuz-linux-lts"

PRESETS=('default' 'fallback')

default_uki="/efi/EFI/Linux/arch-linux-lts.efi"

fallback_uki="/efi/EFI/Linux/arch-linux-lts-fallback.efi"
fallback_options="-S autodetect"
EOF
fi


# installing boot loader

bootctl install

if [[ $de_choice == "SERVER" ]]; then
cat > /efi/loader/loader.conf <<'EOF'
default arch-linux-lts.efi
timeout 5
console-mode auto
editor no
EOF
else
cat > /efi/loader/loader.conf <<'EOF'
default arch-linux.efi
timeout 5
console-mode auto
editor no
EOF
fi

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
                  Creating user & Password setup
-------------------------------------------------------------------------
"

if [[ $(whoami) = "root" ]]; then
    # use chpasswd to enter $USERNAME:$password
    echo "$(whoami):${root_password}" | chpasswd
    echo "$(whoami) password set"
fi

# Creating username
useradd -m -G wheel -s /bin/bash ${username}

echo "${username}:${password}" | chpasswd
echo "$username password set"

# Adding user to wheel group
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers


echo -ne "
-------------------------------------------------------------------------
                            Time setup
-------------------------------------------------------------------------
"
ln -sf /usr/share/zoneinfo/${timezone} /etc/localtime
hwclock --systohc
echo "Timezone: ${timezone}"

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
echo "Hostname: ${name_of_machine}"


echo -ne "
------------------------------------------------------------------------------------------------
 Configure mkinitcpio & Configure the kernel cmdline & .preset file & Installing the bootloader
------------------------------------------------------------------------------------------------
"
if [[ $PLATFORM == "EFI" ]]; then
    # efi setup funtion (function above of the page)
    efisetup

    # Check if the disk in enqrypted
    if [[ $DISK_ENCRYPT = 'y' ]]; then
        echo "rd.luks.name=${LUKS_UUID}=cryptlvm root=/dev/archvolume/root rw" > /etc/kernel/cmdline
    else
        echo "root=/dev/mapper/archvolume-root rw" > /etc/kernel/cmdline
    fi

elif [[ $PLATFORM == "BIOS" ]]; then
    # Bios setup funtion (function above of the page)
    biossetup

    # Detecting other operating systems (This is handy if the user has multiple disks on his bios computer)
    pacman -S os-prober --needed --noconfirm
    echo 'GRUB_DISABLE_OS_PROBER=false' >> /etc/default/grub

    # Check if the disk is encrypted
    if [[ $DISK_ENCRYPT = 'y' ]]; then
        # 1. Force enable cryptodisk
        sed -i 's/^#\?GRUB_ENABLE_CRYPTODISK=.*/GRUB_ENABLE_CRYPTODISK=y/' /etc/default/grub

        # 2. Append to GRUB_CMDLINE_LINUX_DEFAULT instead of overwriting
        sed -i "s|^GRUB_CMDLINE_LINUX_DEFAULT=\"\(.*\)\"|GRUB_CMDLINE_LINUX_DEFAULT=\"\1 cryptdevice=UUID=${LUKS_UUID}:cryptlvm root=UUID=${ROOT_UUID}\"|" /etc/default/grub
    fi

    grub-mkconfig -o /boot/grub/grub.cfg
fi

echo -ne "
-------------------------------------------------------------------------
                            mkinitcpio
-------------------------------------------------------------------------
"

mkinitcpio -P



echo "Finished 1-preinstall.sh"
