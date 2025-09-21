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
                        Password setup
-------------------------------------------------------------------------
"
passwd

echo -ne "
-------------------------------------------------------------------------
                            Time setup
-------------------------------------------------------------------------
"

ln -sf /usr/share/zoneinfo/America/Curacao /etc/localtime   # nog responsive maken
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
pacman -S terminus-font
echo "KEYMAP=us" >> /etc/vconsole.conf && echo "FONT=ter-132b" >> /etc/vconsole.conf


echo -ne "
-------------------------------------------------------------------------
                        Network configuration
-------------------------------------------------------------------------
"

# setting up host name
echo "arch" >> /etc/hostname
systemctl enable NetworkManager


echo -ne "
-------------------------------------------------------------------------
                        Configure mkinitcpio
-------------------------------------------------------------------------
"

sed -i 's/^HOOKS=(.*)/HOOKS=(base systemd autodetect microcode modconf kms keyboard sd-vconsole block sd-encrypt lvm2 filesystems fsck)/' /etc/mkinitcpio.conf


echo -ne "
-------------------------------------------------------------------------
                    Configure the kernel cmdline
-------------------------------------------------------------------------
"
source /usr/local/share/Archinstaller/configs/setup.conf

LUKS_UUID=$(blkid -s UUID -o value "$partition2")
echo "rd.luks.name=$LUKS_UUID=cryptlvm root=/dev/archvolume/root rw" > /mnt/etc/kernel/cmdline


echo -ne "
-------------------------------------------------------------------------
                        .preset file
-------------------------------------------------------------------------
"

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


echo -ne "
-------------------------------------------------------------------------
                    Installing the bootloader
-------------------------------------------------------------------------
"

cat > /efi/loader/loader.conf <<'EOF'
default arch-linux.efi
timeout 5
console-mode auto
editor no
EOF

systemctl enable systemd-boot-update.service
mkinitcpio -P

echo -ne "
-------------------------------------------------------------------------
                    Installing done!
-------------------------------------------------------------------------
"
