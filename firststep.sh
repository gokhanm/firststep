#!/bin/bash
# For personal usage
# Apply personal settings to new fresh linux os installation
# GNU GENERAL PUBLIC LICENSE
# Gokhan MANKARA <gokhan@mankara.org>

source includes/version
source includes/functions.sh

# root check
if [ "$EUID" -ne 0 ]; then
    echo "$(redb "ERROR") $(textb "Please run as root")"
    exit 1
fi

cat includes/banner
echo "$(textb "First Step Installation Script Version:") $(textb "$version")"
echo "$(textb "Installation starting please wait.")"
sleep 3

# create user if not exists
create_user

# Detecting OS 
find_os
echo "$(textb "Operation System: ")$(textb "$os")"

# if os debian found use apt-get update command
update_repo

# Install packages from settings/packages
readarray packages < "settings/packages"

# if array is not empty
if [ ! -z "$packages" ]; then
    for pack in "${packages[@]}"
    do
        # if package not start with "#"
        if [[ ! "$pack" == "#"* ]]; then
            install_package "$pack"
        fi
    done
    # After installation complate, upgrade debian
    # packages
    upgrade_repo
fi

# Apply custom keyboard shortcuts settings from settings/keyboard_shortcuts
readarray shortcuts < "settings/keyboard_shortcuts"

# if array is not empty
if [ ! -z "$shortcuts" ]; then
    for key in "${shortcuts[@]}"
    do
        if [[ ! "$key" == "#"* ]];then
            keyboard_shortcut $key 
        fi
    done
fi

# SSD check, if found apply fstab settings in settings/ssd 
ssd_check

# Gnome shell extensions installation from settings/extensions
readarray extensions < "settings/extensions"

if [ ! -z "$extensions" ]; then
    for ext_id in "${extensions[@]}"
    do
        if [[ ! "$ext_id" == "#"* ]];then
            gnome_shell_ext $ext_id
        fi
    done
fi

# root and user bash aliases
bash_aliases

# User dotfiles files
dot_files

# User vim folder settings
vim_settings

# Installation Complete. Ask for restart the system
restart_system
