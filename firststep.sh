#!/bin/bash
# For personal usage
# Apply personal settings to new fresh linux os installation
# GNU GENERAL PUBLIC LICENSE
# Gokhan MANKARA <gokhan@mankara.org>


# root check
if [ "$EUID" -ne 0 ]; then
    echo "$(textb "ERROR") $(textb "Please run as root")"
    exit 1
fi

cat includes/banner
source includes/version
source includes/functions.sh

echo "$(textb "First Step Installation Script Version:") $(textb "$version")"

# Detecting OS 
find_os
echo "$(textb "Operation System: ")$(textb "$os")"

# if os debian found use apt-get update command
update_repo

packages=(`cat "settings/packages"`)

# if array is not empty
if [ ! -z "$packages" ]; then
    for pack in "${packages[@]}"
    do
        # if package not start with "#"
        if [[ ! "$pack" == "#"* ]]; then
            install_package "$pack"
        fi
    done
fi

# Apply custom keyboard shortcuts settings in settings/keyboard_shortcuts
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
