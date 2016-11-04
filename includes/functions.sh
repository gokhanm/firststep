#!/bin/bash
# All first step installation functions

tmp="/tmp/firststep"

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
        for user in "${usernames[@]}"
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

upgrade_repo () {
    if [[ "$os" == "Debian" ]]; then 
        textb "Upgrading Debian Packages"
        apt-get upgrade -y
        if [ $? -eq 0 ]; then
            echo "$(greenb "OK") $(textb "Debian Packages Upgraded")"
        else
            echo "$(redb "ERROR") $(textb "Debian Package Upgrade Error")"
            exit 1
        fi
    fi
}

# Install Package Function from settings/install
install_package () {
    readarray packages < "settings/packages"
    
    if [ ! -z "$packages" ]; then
        for pack in "${packages[@]}"
        do
            if [[ ! "$pack" == "#"* ]]; then
                echo "$(textb "Installing Package: ") $(textb "$pack")"    
                if [[ "$os" == "Debian" ]]; then
                    apt-get install -y $pack
                    if [ $? -eq 0 ]; then
                        echo "$(greenb "OK") $(textb "Installation complate: $pack")"
                    else
                        echo "$(redb "ERROR") $(textb "Installation not complate: $pack")"
                        exit 1
                    fi
                elif [[ "$os" == "CentOS" ]] || [[ "$os" == "Redhat" ]]; then
                    yum install -y $pack
                    if [ $? -eq 0 ]; then
                        echo "$(greenb "OK") $(textb "Installation complate: $pack")"
                    else
                        echo "$(redb "ERROR") $(textb "Installation not complate: $pack")"
                        exit 1
                    fi                    
                fi                   
            fi
        done
    fi
}

# Apply keyboard shortcut settings from settings/keyboard_shortcuts
keyboard_shortcut () {
    readarray shortcuts < "settings/keyboard_shortcuts"

    if [ ! -z "$shortcuts" ]; then
        for key in "${shortcuts[@]}"
        do
            if [[ ! "$key" == "#"* ]];then
                if [[ ! "$(pgrep -f gnome | wc -l)" == 0  ]]; then
                    if [[ "$(gnome-shell --version | awk '{print $3 }' | cut -d'.' -f1)" == "3"* ]]; then
                        echo "$(textb "Desktop Environment Found: ") $(textb "Gnome 3")"
                        #su - $user -c "gsettings set org.gnome.desktop.wm.keybindings $1 \"$2\""
                        su - $user -c "gsettings set org.gnome.desktop.wm.keybindings $key"
                        if [ $? -eq 0 ];then
                            echo "$(greenb "OK") $(textb "Keyboard shortcut added: $key")"
                        else    
                            echo "$(redb "ERROR") $(textb "Keyboard shortcut not added: $key")"
                            exit 1
                        fi
                    fi  
                fi
            fi
        done
    fi
}

# If ssd found apply settings from settings/ssd 
ssd_check () {
    # You should get 1 for hard disks and 0 for a SSD. 
    partition="$(fdisk -l 2>/dev/null | grep '/dev/sd[a-z][1-9]' | grep "Linux" | grep -v "swap" | awk '{print $1}')"
    disk="$(printf '%s\n' "${partition//[[:digit:]]/}" | cut -d'/' -f3)"
    ssd="$(cat /sys/block/$disk/queue/rotational)"

    if [[ "$ssd" == "0" ]]; then
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
                echo "$(greenb "OK") $(textb "Resuming without applying ssd
                settings")"
            ;;
            * )
                echo "$(textb "Please answer Y/y/n/N")"
                ssd_check
            ;;
        esac
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
    running_path
    readarray extensions < "settings/extensions"

    if [ ! -z "$extensions" ]; then
        for ext_id in "${extensions[@]}"    
        do
            if [[ ! "$ext_id" == "#"* ]]; then
                if [[ ! "$(pgrep -f gnome | wc -l)" == "0"  ]]; then
                    echo "$(textb "Installing Gnome Extensions") $(textb "$ext_id")"
                    su - $user -c "bash $current_path/tools/gnome-shell-extension-installer $ext_id --restart-shell 2> /dev/null"
                fi
            
            fi
        done
    fi
}

# Current running path
running_path () {
    export current_path="`pwd`"
}

# Restart system function
restart_system () {
    while true; do
        read -p "$(redb "WARNING") $(textb "Installation Complate. Do you want to
        restart the system? [Yy / Nn]")" yn

        case $yn in
            [Yy]* )
                echo "$(textb "Restarting the system")"
                reboot
            ;;
            [Nn]* )
                echo "$(textb "Installation Complate. Exit.")"
                exit 1
            ;;
            * )
                echo "$(textb "Please answer Y/y/n/N")"
                break
            ;;
        esac
    done
}

# Bash aliases function 
# ~/.bash_aliases
bash_aliases () {
    readarray aliases < "settings/aliases"
    if [ ! -z "$aliases" ]; then
        for alias in "${aliases[@]}"
        do
            if [[ ! "$alias" == "#"* ]]; then
                if  [[ ! "$alias" == "source"* ]]; then 
                    user="$(echo $alias | cut -d'|' -f1)"
                    user_alias="$(echo $alias | cut -d'|' -f2)"
                    
                    if [[ "$user" == "root" ]];then
                        check_bash_aliases "~/.bash_aliases"
                        echo "alias $user_alias" >> ~/.bash_aliases
                    else
                        check_bash_aliases "/home/$user/.bash_aliases"
                        echo "alias $user_alias" >> /home/$user/.bash_aliases
                        chown $user:$user /home/$user/.bash_aliases
                    fi
                fi
            fi
        done
    fi
}

# Add bash_aliases source if not found in bashrc
check_bash_aliases () {

    bash_aliases="$(test $(grep "~/.bash_aliases" $1 | wc -l) -gt 0; echo $?)"
    
    if [[ "$bash_aliases" == "1" ]]; then
        echo "[ -f ~/.bash_aliases ] && . ~/.bash_aliases" >> $1
    fi
}

# Dotfiles function
dot_files () {
    readarray dotfiles < "settings/dotfiles"
    
    if [ ! -z "$dotfiles" ]; then
        for dotfile in "${dotfiles[@]}"
        do
            if [[ ! "$dotfile" == "#"* ]]; then
                duser="$(echo $dotfile | cut -d'|' -f1)"
                orj_path="$(echo $dotfile | cut -d'|' -f2)"
                back_path="$(echo $dotfile | cut -d'|' -f3)"
                
                if [ -z "$duser" ]; then
                    duser=$user
                fi
                
                last=${back_path##*/}
                # I think no need to change name
                # because we move the file to new path 
                # new_name=".$last"
                
                download_file $back_path $last
                                               
                new_path="$tmp/$new_name"
                
                su - $duser -c "cp $new_path $orj_path"
                if [ $? -eq 0 ];then
                    echo "$(textb "Copying to") $(textb "$orj_path") $(textb "for $duser")"
                else    
                    echo "$(redb "Copying to") $(textb "$orj_path") $(textb "for $duser")"
                    exit 1
                fi                                          
            fi
            unset $duser           
        done
    fi
}

# Download given file to tmp folder
download_file () {
    back_path=$1
    new_name=$2
    
    if [ ! -d "$tmp" ];then
        mkdir $tmp
    fi
      
    echo "$(textb "Downloading file:") $(textb $last)"
    curl $1 -# --output $tmp/$new_name    
}

# Clone or create path in to the ~/.vim/ folder
vim_settings () {
    readarray vimsets < "settings/vim_settings"
    
    if [ ! -z "$vimsets" ]; then
        for vimset in "${vimsets[@]}"
        do
            if [[ ! "$vimset" == "#"* ]]; then
                duser="$(echo $vimset | cut -d'|' -f1)"
                rule="$(echo $vimset | cut -d'|' -f2)"
                path="$(echo $vimset | cut -d'|' -f3)"
                
                if [ -z "$duser" ]; then
                    duser=$user
                fi                
                
                if [[ "$rule" == "path" ]]; then
                    #    echo "$(textb "Creating path") $(textb "$path") $(textb "for $duser")"
                    su - $duser -c "if [ ! -d "$path" ]; then mkdir -p $path; fi"
                    sleep 1
                elif [[ "$rule" == "clone" ]]; then
                    git_clone="$(echo $vimset | cut -d'|' -f4)"
                    
                    if [ ! -z "$git_clone" ];then                   
                        echo "$(textb "Cloning to") $(textb "$path") $(textb "for $duser")"
                        su - $duser -c "cd $path && git clone $git_clone"
                        sleep 1
                    else
                        echo "$(redb "ERROR") $(textb "Cloning path not found in settings/vim_settings")"
                        exit 1
                    fi
                fi
            fi      
            unset $duser
        done
    fi
}
