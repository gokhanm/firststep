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

# Install Packages
install_package

# After installation complate, upgrade debian
# packages
upgrade_repo

# Apply custom keyboard shortcuts settings from settings/keyboard_shortcuts
keyboard_shortcut

# SSD check, if found apply fstab settings in settings/ssd 
ssd_check

# Gnome shell extensions installation from settings/extensions
gnome_shell_ext

# root and user bash aliases
bash_aliases

# User dotfiles files
dot_files

# User vim folder settings
vim_settings

# Short links 
short_links

# Tweak Settings
tweak_settings

# Activate Favorite Apps
favorite_apps

# Installation Complete. Ask for restart the system
restart_system
