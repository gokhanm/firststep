#!/bin/bash
# For personal usage
# Apply personal settings to new fresh linux os installation
# GNU GENERAL PUBLIC LICENSE
# Gokhan MANKARA <gokhan@mankara.org>

source includes/version
source includes/functions.sh
source includes/dialog_functions.sh

# root check
if [ "$EUID" -ne 0 ]; then
    echo "$(redb "ERROR") $(textb "Please run as root")"
    exit 1
fi

# Detecting OS 
find_os

# install dialog package
install_package "dialog"

info_box "Processing, please wait" 3 34 3

welcome_message="Operation System: $os
Script Version: $version"

message_box "First Step Installation" "Welcome to first step" "$welcome_message" 8 60

# create user if not exists
create_user

# create tmp folder
export tmp="/tmp/firststep"
[ ! -d $tmp ] && su - $user -c "mkdir -p $tmp"

# if os debian found use apt-get update command
update_repo

cmd=(dialog --separate-output --backtitle " First Step Installation" \
    --checklist "Which settins do you want to:" 22 76 16)
options=(1 "Install Packages" on    # any option can be set to default to "off"
         2 "Upgrade Repo" on
         3 "Keyboard Shortcuts" on
         4 "SSD Check" on
         5 "Gnome Shell Extensions" on
         6 "Bash Aliases" on
         7 "User Dotfiles" on
         8 "User Vim Settings" on
         9 "Short Links" on
         10 "Tweak Settings" on
         11 "User Favorite Apps" on)
choices=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
clear
for choice in $choices
do
    case $choice in
        1)
            # Install Packages
            install_package
        ;;
        2)
            # After installation complate, upgrade debian
            # packages
            upgrade_repo
        ;;
        3)
            # Apply custom keyboard shortcuts settings from settings/keyboard_shortcuts
            keyboard_shortcut
        ;;
        4)
            # SSD check, if found apply fstab settings in settings/ssd 
            ssd_check
        ;;
        5)
            # Gnome shell extensions installation from settings/extensions
            gnome_shell_ext
        ;;
        6)
            # root and user bash aliases
            bash_aliases
        ;;
        7)
            # User dotfiles files
            dot_files
        ;;
        8)
            # User vim folder settings
            vim_settings
        ;;
        9)            
            # Short links 
            short_links
        ;;
        10)
            # Tweak Settings
            tweak_settings
        ;;
        11)
            # Activate Favorite Apps
            favorite_apps
        ;;
    esac
done

# Installation Complete. Ask for restart the system
restart_system
