#!/bin/bash
# Dialog functions to be used during installation

message_box () {
    backtitle=$1
    title=$2
    msg=$3
    height=$4
    width=$5
    
    dialog --backtitle "$backtitle" --title "$title" --msgbox "$msg" $height $width
}

info_box () {
    msg=$1
    height=$2
    width=$3
    sleep_time=$4
    
    dialog --infobox "$msg" $height $width ; sleep $sleep_time
}

edit_box () {
    backtitle=$1
    title=$2
    path=$3
    height=$4
    width=$5
    
    dialog --title "$2" -- backtitle "$1" --editbox "$path" $height $width
}

input_box () {
    backtitle=$1
    title=$2
    inputbox=$3
    height=$4
    width=$5
    file=$6
    
    dialog --title "$title" --backtitle "$backtitle" --inputbox "$inputbox" $height $width 2>$file
    
    retval=$?
    name=$(<$file)
   
    case $retval in
      0)
        if [ -z "$name" ]; then
            input_box "$backtitle" "$title" "$inputbox" $height $width "$file"
        else
            echo "$name" > $file
        fi
      ;;
      1)
        echo "Cancel pressed."
        exit 0
      ;;
      255)
        echo "ESC pressed."
        exit 1
      ;;
esac
}

password_box () {
    backtitle=$1
    title=$2
    height=$3
    width=$4
    
    PASSWORD=$(dialog --backtitle "$backtitle" --title "$title" --clear --passwordbox "Enter your password for $user" $height $width 3>&1 1>&2 2>&3)

    ret=$?
    
    case $ret in
      0)
        passwd $PASSWORD;;
      1)
        echo "Cancel pressed.";;
      255)
        echo "ESC pressed.";;
    esac
}

