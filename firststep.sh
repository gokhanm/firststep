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

# create tmp folder
export tmp="/tmp/firststep"
[ ! -d $tmp ] && su - $user -c "mkdir -p $tmp"

# Detecting OS 
find_os
echo "$(textb "Operation System: ")$(textb "$os")"

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

# Installation Complete. Ask for restart the system
restart_system
