# Archinstaller

A bash script for automated Arch Linux installation, primarily designed for virtual machine deployments.

## ⚠️ Warning

This script is **not thoroughly tested** in all configurations. Use at your own risk, especially on physical hardware. Always ensure you have backups of important data before proceeding.

## Recommended Use Case

This installer is specifically optimized for setting up Arch Linux in virtual machines.

## Installation

1. Boot into the Arch Linux live ISO
2. Install git:
   ```bash
   pacman -Sy git
   ```
3. Clone this repository:
   ```bash
   git clone <repository-url>
   ```
4. Navigate to the directory and run the installer:
   ```bash
   cd Archinstaller
   bash archinstaller.sh
   ```

## Configuration

You can customize the installation language and other settings in the configuration file before running the script.
