#!/bin/bash

# text bold color terminal output
textb() {
	echo $(tput bold)${1}$(tput sgr0);
}

# green bold color terminal output
greenb() {
	echo $(tput bold)$(tput setaf 2)${1}$(tput sgr0);
}

# red bold color terminal output
redb() {
	echo $(tput bold)$(tput setaf 1)${1}$(tput sgr0);
}

# creater user
create_user () {
    readarray usernames < "settings/user"
    if [ ! -z "$usernames" ]; then
        for user in "${extensions[@]}"
        do
            if [[ ! "$user" == "#"* ]];then
                echo "$(greenb "INFO") $(textb "Checking User: $user")"
                check_user="$(id -u $user)"

                if [ $? -eq "0" ]; then
                    echo "$(greenb "INFO") $(textb "User already exists.
                    Passing...")"
                else
                    adduser $user
                    passwd $user
                    echo "$(greenb "INFO") $(textb "User created with password")"
                fi
                export $user
            fi
        done
    else
        echo "$(redb "ERROR") $(textb "You have to write username in
        settings/user. Functions uses this username for installation.")"
        exit 1
    fi
}

# Finding OS Function
find_os () {
    export os="$(awk '{ print $1 }' /etc/issue | head -n 1)"
}

# If debian found using apt-get update command function
update_repo () {
    if [[ "$os" == "Debian" ]]; then 
        textb "Updating Debian Repo"
        apt-get update
        if [ $? -eq 0 ]; then
            echo "$(greenb "OK") $(textb "Debian Repo Updated")"
        else
            echo "$(redb "ERROR") $(textb "Debian Repo Update Error")"
            exit 1
        fi
    fi
}

# Install Package Function
install_package () {
    echo "$(textb "Installing Package: ") $(textb "$1")"
    if [[ "$os" == "Debian" ]]; then
        apt-get install -y $1
        if [ $? -eq 0 ]; then
            echo "$(greenb "OK") $(textb "Installation complate: $1")"
        else
            echo "$(redb "ERROR") $(textb "Installation not complate: $1")"
            exit 1
        fi
    elif [[ "$os" == "CentOS" ]] || [[ "$os" == "Redhat" ]]; then
        yum install -y $1
        if [ $? -eq 0 ]; then
            echo "$(greenb "OK") $(textb "Installation complate: $1")"
        else
            echo "$(redb "ERROR") $(textb "Installation not complate: $1")"
            exit 1
        fi
    fi
}

# Apply keyboard shortcut settings from settings/keyboard_shortcuts
keyboard_shortcut () {
    name=$1
    key=$2

    if [[ ! "$(pgrep -f gnome | wc -l)" == 0  ]]; then
        if [[ "$(gnome-shell --version | awk '{print $3 }' | cut -d'.' -f1)" == "3"* ]]; then
            echo "$(textb "Desktop Environment Found: ") $(textb "Gnome 3")"
            su - $user -c "gsettings set org.gnome.desktop.wm.keybindings $name $key"
            if [ $? -eq 0 ];then
                echo "$(greenb "OK") $(textb "Keyboard shortcut added: $name $key")"
            else    
                echo "$(greenb "ERROR") $(textb "Keyboard shortcut not added: $name $key")"
                exit 1
            fi
        fi
    fi
}

# If ssd found apply settings from settings/ssd 
ssd_check () {
    # You should get 1 for hard disks and 0 for a SSD. 
    partition="$(fdisk -l 2>/dev/null | grep '/dev/sd[a-z][1-9]' | grep "Linux" | grep -v "swap" | awk '{print $1}')"
    disk="$(printf '%s\n' "${partition//[[:digit:]]/}" | cut -d'/' -f3)"
    ssd="$(cat /sys/block/$disk/queue/rotational)"

    if [[ "$ssd" == "0" ]]; then
        while true; do
            read -p "$(redb "WARNING") $(textb "These changes may damage the
            system. Do you want to continue? [Yy / Nn]")" yn
            case $yn in
                [Yy]* )
                    parsing_ssd_settings
                    echo "$(textb "SSD Found. Finding Linux Installation on Disk")"
                    echo "$(textb "Linux partition: ") $(textb "$partition")"
                    echo "$(textb "Finding Partition in /etc/fstab")"
                    sda_in_fstab="$(test $(grep $partition /etc/fstab | grep -v "#" | wc -l) -gt 0; echo $?)"
                    
                    if [[ "$sda_in_fstab" == "1" ]]; then
                        echo "$(textb "$partition not found in /etc/fstab")"
                        echo "$(textb "Finding UUID for ") $(textb "$partition")"
                        uuid="$(blkid $partition | awk '{print $2}' | cut -d'"' -f2)"
                        echo "$(textb "UUID Found:") $(textb "$uuid")"
                        
                        apply_ssd_settings $uuid
                    else
                        apply_ssd_settings $partition
                    fi
                ;;
                [nN]* )
                    echo "$(greenb "OK") $(textb "Resuming without application changes..")"
                    break
                ;;
                * )
                    echo "$(textb "Please answer Y/y/n/N")"
                ;;
            esac
        done
    fi
}

# parsing personal settings from settings/ssd
parsing_ssd_settings () {
    ssd_settings=(`cat "settings/ssd"`)

    if [ ! -z "$ssd_settings" ];then
        for line in ${ssd_settings[@]}
        do
            if [[ ! "$line" == "#"* ]];then
                export mount_point="$(echo $line | cut -d'|' -f1)"
                export options="$(echo $line | cut -d'|' -f2)"
            fi
        done
    fi
}

# apply ssd settings to fstab function
apply_ssd_settings () {
    cp /etc/fstab /tmp/

    if [ $? -eq 0 ]; then
        echo "$(greenb "OK") $(textb "Backup /etc/fstab in tmp")"

        old_options="$(grep $1 /etc/fstab | awk '{print $4}')"
        new_options=$options

        echo "$(textb "Changing $old_options with $new_options")"

        sed -i "s/$old_options/$new_options/" /etc/fstab

        if [ $? -eq 0 ];then
            echo "$(greenb "OK") $(textb "Editing fstab complate")"
            echo "$(greenb "INFO") $(textb "Validating fstab settings")"

            mount -a

            if [ $? -eq 0 ];then
                echo "$(greenb "OK") $(textb "Fstab validate complate")"
            else
                echo "$(redb "ERROR") $(textb "Fstab settings error. Check fstab settings")"
                exit 1
            fi
        else
            echo "$(redb "ERROR") $(textb "Editing fstab complate")"
            exit 1
        fi
    else
        echo "$(redb "ERROR") $(textb "Backup /etc/fstab in tmp")"
        exit 1
    fi
}

# install gnome shell extensions
gnome_shell_ext () {
    if [[ ! "$(pgrep -f gnome | wc -l)" == 0  ]]; then
        echo "$(textb "Installing Gnome Extensions")"
        bash tools/gnome-shell-extension-installer $1 --restart-shell
    fi
}

