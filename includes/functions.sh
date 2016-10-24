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

# Finding OS Function
find_os () {
    export os="$(awk '{ print $1 }' /etc/issue | head -n 1)"
}

# If debian found using apt-get update command function
update_repo () {
    find_os

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
    find_os

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

# Apply keyboard shortcut settings in settings/keyboard_shortcuts
keyboard_shortcut () {
    user=$1
    name=$2
    key=$3

    if [[ ! "$(pgrep -f gnome | wc -l)" == 0  ]]; then
        if [[ "$(gnome-shell --version | awk '{print $3 }' | cut -d'.' -f1)" == "3"* ]]; then
            echo "$(textb "Desktop Environment Found: ") $(textb "Gnome 3")"
            su - $user -c "gsettings set org.gnome.desktop.wm.keybindings $name $key"
            if [ $? -eq 0 ];then
                echo "$(greenb "OK") $(textb "Keyboard shortcut added: $2 $3")"
            else    
                echo "$(greenb "ERROR") $(textb "Keyboard shortcut not added: $2 $3")"
            fi
        fi
        
    fi

}

