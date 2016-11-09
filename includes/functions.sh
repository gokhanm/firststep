#!/bin/bash
# All first step installation functions

source includes/dialog_functions.sh

# creater user
create_user () {
    readarray usernames < "settings/user"
    if [ ! -z "$usernames" ]; then
        for user in "${usernames[@]}"
        do
            if [[ ! "$user" == "#"* ]];then
                info_box "Checking User: $user" 3 34 2 
                check_user="$(id -u $user)"

                if [ $? -eq "0" ]; then
                    info_box "User already exists." 3 34 2 
                else
                    adduser --disabled-password $user
                    password_box "First Step Installation" "Password" 10 30
                    info_box "User created with password" 3 34 2 
                fi
                export $user
            fi
        done
    else
        input_box 'First Step Installation' 'Please write username' 'Functions uses username for installation. Please write username' 8 60 'settings/user'
        create_user
    fi
}

# Finding OS Function
find_os () {
    export os="$(awk '{ print $1 }' /etc/issue | head -n 1)"
}

# If debian found using apt-get update command function
update_repo () {
    if [[ "$os" == "Debian" ]]; then 
        apt-get update > /dev/null
       
        if [ $? -eq 0 ]; then
            info_box "Updated Debian Repo Update" 3 34 2
        else
            info_box "ERROR. Debian Repo Update" 3 34 2
            exit 1
        fi
    fi
}

upgrade_repo () {
    if [[ "$os" == "Debian" ]]; then 
        #info_box "Upgrading Debian Packages" 10 80 5
        
        apt-get upgrade -y > /dev/null
        if [ $? -eq 0 ]; then
            info_box "Upgraded Debian Repo Update" 3 34 2
        else
            info_box "ERROR. Debian Repo Upgrade" 3 34 2
            exit 1
        fi
    fi
}

# Install Package Function from settings/install
install_package () {
    # if argument given
    if [ ! -z "$1" ]; then
        apt-get install -y $1 2>&1 > /dev/null
    else
        readarray packages < "settings/packages"

        if [ ! -z "$packages" ]; then
            for pack in "${packages[@]}"
            do
                if [[ ! "$pack" == "#"* ]]; then
                    info_box "Installing Package: $pack" 3 40 2
                    if [[ "$os" == "Debian" ]]; then
                        apt-get install -y $pack 2>&1 > /dev/null
                        if [ $? -eq 0 ]; then
                            info_box "Installed Package: $pack" 3 40 2
                        else
                            info_box "ERROR Installation package: $pack" 3 40 2
                            exit 1
                        fi
                    elif [[ "$os" == "CentOS" ]] || [[ "$os" == "Redhat" ]]; then
                        yum install -y $pack 2>&1  > /dev/null
                        if [ $? -eq 0 ]; then
                            info_box "Installed Package: $pack" 3 40 2
                        else
                            info_box "ERROR Installation package: $pack" 3 40 2
                            exit 1
                        fi
                    else
                        info_box "ERROR Operation System not understood. OS: $os" 3 40 2
                        exit 1                
                    fi                   
                fi
            done
        fi
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
                        info_box "Desktop Environment Found: Gnome 3" 3 40 2 
                        su - $user -c "gsettings set org.gnome.desktop.wm.keybindings $key"
                        if [ $? -eq 0 ];then
                            info_box "Keyboard shortcut added: $key" 3 50 2
                        else    
                            info_box "Keyboard shortcut not added: $key" 3 50 2
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
        yes_no "First Step Install" "Fstab Configuration" "These changes may damage the system. Do you want to continue?" 8 60

        parsing_ssd_settings
        info_box "SSD Found. Finding Linux Installation on Disk" 3 40 2
        info_box "Linux partition: $partition" 3 50 2
        info_box "Finding Partition in /etc/fstab" 3 40 2        
        sda_in_fstab="$(test $(grep $partition /etc/fstab | grep -v "#" | wc -l) -gt 0; echo $?)"
        
        if [[ "$sda_in_fstab" == "1" ]]; then
            info_box "$partition not found in /etc/fstab" 3 50 2
            info_box "Finding UUID for $partition" 3 40 2   
            uuid="$(blkid $partition | awk '{print $2}' | cut -d'"' -f2)"
            info_box "$partition UUID: $uuid" 3 50 2
            apply_ssd_settings $uuid
        else
            apply_ssd_settings $partition
        fi
        
        ssd_trim_support
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
        info_box "Backup /etc/fstab in tmp" 3 40 2

        old_options="$(grep $1 /etc/fstab | awk '{print $4}')"
        new_options=$options
        
        info_box "Changing $old_options with $new_options" 3 50 2

        sed -i "s/$old_options/$new_options/" /etc/fstab

        if [ $? -eq 0 ];then
            info_box "Edited fstab complate" 3 40 2

            mount -a

            if [ $? -eq 0 ];then
                info_box "Fstab validate complate" 3 40 2
            else
                info_box "Fstab settings error. Check fstab settings" 3 40 2
                exit 1
            fi
        else
            info_box "ERROR.Edit fstab complate" 3 40 2
            exit 1
        fi
    else
        info_box "ERROR.Backup /etc/fstab in tmp" 3 40 2
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
                    info_box "Installing Gnome Extension. Id: $ext_id" 3 50 2
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
    yes_no "First Step Install" "Restart the System" "Installation Complate. Do you want to restart?" 8 60

    info_box "Restarting the system..." 3 50 2
    restart

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
                    duser="$(echo $alias | cut -d'|' -f1)"
                    user_alias="$(echo $alias | cut -d'|' -f2)"
                    
                    if [[ "$duser" == "root" ]];then
                        bashrc="/root/.bashrc"
                        bash_aliases="/root/.bash_aliases"
                    else
                        bashrc="/home/$user/.bashrc"
                        bash_aliases="/home/$user/.bash_aliases"
                    fi
                    
                    aliase_check="$(test $(grep "alias $user_alias" $bash_aliases | wc -l) -gt 0; echo $?)"
                    
                    if [[ "$aliase_check" == "1" ]]; then
                        # i can use su command here. But double quotes gets problem in echo command
                        # fix later
                        echo "alias $user_alias" >> $bash_aliases
                        
                        if [ $? -eq 0 ];then
                            info_box "Bash Aliases applied" 3 40 2
                            if [[ -z "$duser" ]]; then
                                chown $user:$user $bash_aliases
                            fi                            
                        else    
                            info_box "ERROR.Bash Aliases applied" 3 40 2
                            exit 1
                        fi
                    fi
                fi
            fi
            unset $duser
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
                new_name=".$last"
                
                download_file $back_path $last
                                               
                new_path="$tmp/$new_name"
                
                su - $duser -c "cp $new_path $orj_path"
                if [ $? -eq 0 ];then
                    info_box "Copying to $orj_path for $duser" 3 50 2
                else
                    info_box "ERROR. Copying to $orj_path for $duser" 3 50 2
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
        su - $user -c "mkdir $tmp"
    fi
      
    info_box "Downloading file: $last" 3 50 2
    curl $1 -s --output $tmp/$new_name    
}

# Clone or create path in to the ~/.vim/ folder
vim_settings () {
    # 0: folder not found
    # 1: folder found
    # if file created by root the user takes permission error
    su - $user -c "echo '0' > $tmp/folder_found"
    
    readarray vimsets < "settings/vim_settings"
    
    if [ ! -z "$vimsets" ]; then
        for vimset in "${vimsets[@]}"
        do
            if [[ ! "$vimset" == "#"* ]]; then
                duser="$(echo $vimset | cut -d'|' -f1)"
                rule="$(echo $vimset | cut -d'|' -f2)"
                path="$(echo $vimset | cut -d'|' -f3)"
                url="$(echo $vimset | cut -d'|' -f4)"
                
                if [ -z "$duser" ]; then
                    duser=$user
                fi                
                
                if [[ "$rule" == "path" ]]; then
                    #    echo "$(textb "Creating path") $(textb "$path") $(textb "for $duser")"
                    su - $duser -c "[ ! -d "$path" ] && mkdir -p $path"
                    sleep 1
                elif [[ "$rule" == "clone" ]]; then                                                        
                    if [ ! -z "$url" ];then     
                    
                        repo_name=${url##*/}
                        repo_folder_name=${repo_name%.*}
                        
                        su - $user -c "[ -d $path/$repo_folder_name ] && echo '1' > $tmp/folder_found || echo '0' > $tmp/folder_found"
                        
                        if [ "$(cat $tmp/folder_found)" -eq 0 ]; then
                            info_box "Cloning to $path for $duser" 3 50 2
                            su - $duser -c "cd $path && git clone $url"
                            sleep 1
                        else
                            info_box "Folder $repo_folder_name for $duser found passing...." 3 50 2
                        fi
                    else
                        info_box "ERROR. Cloning path not found in settings/vim_settings" 3 50 2                  
                        exit 1
                    fi
                elif [[ "$rule" == "copy" ]]; then
                    last=${url##*/}
                    download_file $url $last
                    new_path="$tmp/$last"
                    
                    su - $duser -c "[ ! -d $path ] && mkdir -p $path"
                    
                    su - $duser -c "cp $new_path $path"
                    if [ $? -eq 0 ];then
                        info_box "Copying to $path for $duser" 3 50 2
                    else    
                        info_box "ERROR. Copying to $path for $duser" 3 50 2                        
                        exit 1
                    fi                                                              
                fi
            fi      
            unset $duser
        done
    fi
}

# Short links function
short_links () {
    readarray short_links < "settings/short_links"
    
    if [ ! -z "$short_links" ]; then
        for link in "${short_links[@]}"
        do
            if [[ ! "$link" == "#"* ]]; then
                target="$(echo $link | cut -d'|' -f1)"
                slink="$(echo $link | cut -d'|' -f2)"
                
                if [ ! -L $slink ]; then
               
                    ln -s $target $slink
                    
                    if [ $? -eq 0 ];then
                        echo "$(textb "Creating short link") $(textb "$target") $(textb "to $slink")"
                        info_box "Creating short link $target to $slink" 3 50 2
                    else    
                        info_box "ERROR.Creating short link $target to $slink" 3 50 2                        
                        exit 1
                    fi
                else
                    info_box "Short Link $slink found passing..." 3 50 2
                fi              
            fi
        done
    fi        
}

# Tweak Settings Function
tweak_settings () {
    readarray tweak_settings < "settings/tweak_settings"
    
    if [ ! -z "$tweak_settings" ]; then
        for ts in "${tweak_settings[@]}"
        do
            if [[ ! "$ts" == "#"* ]]; then
                schema_name="$(echo $ts | cut -d'|' -f1)"
                
                if [[ ! "$(pgrep -f gnome | wc -l)" == "0"  ]]; then
                    gnome_version="$(gnome-shell --version | awk '{print $3 }')"
                    version=${gnome_version%.*}
                    
                    if [[ "$schema_name" == "desktop.calendar" ]]; then                           
                        if [[ "$version" == "3.14" ]]; then
                            schema="org.gnome.shell.calendar"
                        else
                            # Gnome 3.22
                            schema="org.gnome.desktop.calendar"
                        fi
                    fi
                    
                    if [[ "$schema_name" == "desktop.interface" ]]; then
                        schema="org.gnome.desktop.interface"
                    elif [[ "$schema_name" == "nautilus.desktop" ]]; then
                        schema="org.gnome.nautilus.desktop"
                    elif [[ "$schema_name" == "desktop.background" ]]; then
                        schema="org.gnome.desktop.background"
                    elif [[ "$schema_name" == "desktop.wm.preferences" ]]; then
                        schema="org.gnome.desktop.wm.preferences"
                    elif [[ "$schema_name" == "mutter" ]];then
                        schema="org.gnome.mutter"
                    fi   
              
                    key="$(echo $ts | cut -d'|' -f2)"
                    value="$(echo $ts | cut -d'|' -f3)"
                
                    su - $user -c "gsettings set $schema $key $value"
                    if [ $? -eq 0 ];then
                        info_box "Applying tweak settings $schema $key: $value" 3 50 2
                    else    
                        info_box "ERROR. Applying tweak settings $schema $key: $value" 3 50 2                        
                        exit 1
                    fi
                fi            
            fi
        done
    fi
}

# if trim supported. Run cron daily
ssd_trim_support () {
    trim_support="$(test $(hdparm -I /dev/sda | grep "TRIM supported" | wc -l ) -gt 0; echo $?)"
    
    if [[ "$trim_support" == "0" ]]; then
        cron_path="/etc/cron.daily/trim"
        
        cat > $cron_path <<\EOF
#!/bin/sh
LOG=/var/log/trim.log
echo "* $(date -R) *" >> $LOG
fstrim -v / >> $LOG
fstrim -v /home >> $LOG
EOF
        chmod +x $cron_path
    fi
}

# Favorite apps function
# Array must be seperated with comma
favorite_apps () {
    readarray favorite_apps < "settings/favorite_apps"

    if [ ! -z "$favorite_apps" ]; then
        for app in "${favorite_apps[@]}"
        do
            if [[ ! "$app" == "#"* ]];then
                total_array+=($app)  
            fi
        done
            
        with_comma=$(printf ", %s" "${total_array[@]}")
        with_comma=${with_comma:1}
        convert_list="[${with_comma[@]}]"
        
        # for Gnome 3                     
        if [[ ! "$(pgrep -f gnome | wc -l)" == 0  ]]; then
            if [[ "$(gnome-shell --version | awk '{print $3 }' | cut -d'.' -f1)" == "3"* ]]; then
                su - $user -c "gsettings set org.gnome.shell favorite-apps \"$convert_list\""
                
                if [ $? -eq 0 ];then
                    info_box "Activating Favorite Apps \"$convert_list\"" 3 70 2
                else    
                    info_box "ERROR. Activating Favorite Apps \"$convert_list\"" 3 70 2                    
                    exit 1
                fi                        
            fi
        fi
    fi
}
