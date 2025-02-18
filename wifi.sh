#!/bin/bash

##
# This script will provide for limited control of the wireless adapter on the
# CB5-311.

# It makes use of saved wpa configuration files in a ~/wifi folder.  Create a
# configuration by invoking wpa_passphrase and saving the output into
# ~/wifi/SOMETHING.wpa.  The name of the file doesn't matter as long as it ends
# in '.wpa'

IFACE=mlan0

PATH_WPA="${HOME}"/wifi

usage(){
    cat << "EOF"
This script facilitates connecting to saved access points.  It does not use
Network Manager.

Call it with the following options:
    -h - help         - display this help
    -i - interactive  - configure wifi interactively
    -l - list         - list saved access points
    -s SSID           - specify saved ssid
    -p PATH           - specify alternate directory for wpa files
    -k - kill         - stop wpa/wifi activity

Call it with no arguments for info.

To create a configuration file for a saved access point, use wpa_passphrase.

For example:
    wpa_passphrase myssid mypassword > ~/wifi/foo.wpa

Then you may connect to the saved access point thusly:
    wifi.sh -s myssid

To use a different directory for storing wpa files, specify the new path with
-p.  For example:
    wifi.sh -p ~/Wifi -s foo

This will make the script look for .wpa files in ~/Wifi that contain essid foo.
EOF
}

##
# Loops over all the .wpa files in $PATH_WPA and displays essids.
display_saved(){
    echo "Saved networks:"
    for f in ${PATH_WPA}/*.wpa ; do
        echo "   $(grep ssid $f | cut -f2 -d\")"
    done
}

##
# Attempts to connect to a specified essid
#    @param essid
connect(){
    local ESSID="$1"
    #FIXME: does not take into account matching ssids with different passwords
    grep -l ssid=\"${ESSID}\" ${PATH_WPA}/*.wpa 2>&1>/dev/null
    if [ "$?" -ne 0 ] ; then
        echo "Unknown essid, bailing..."
        return 1
    fi
    for FILE in $(grep -l ssid=\"${ESSID}\" ${PATH_WPA}/*.wpa) ; do
        echo "Found ESSID ${ESSID} in $FILE"
        sudo wpa_supplicant -Dwext -i"${IFACE}" -c "${FILE}" -B
        sudo dhclient "${IFACE}"
    done
    return 1
}

##
# Stops any running wpa_supplicant and turns off the interface
kill_wifi(){
    sudo killall wpa_supplicant 2>/dev/null
    while [ "$?" -eq 0 ] ; do
        sudo killall wpa_supplicant 2>/dev/null
    done
    sudo killall dhclient 2>/dev/null
    while [ "$?" -eq 0 ] ; do
        sudo killall dhclient 2>/dev/null
    done
    sudo ifconfig ${IFACE} down
}

##
# Displays current iwconfig status
info(){
    local ESSID=$(iwconfig mlan0 | grep -o ESSID:".*")
    if [ "$?" -eq 0 ] ; then
        echo "wifi connected: $ESSID"
    else
        echo "wifi not connected"
    fi
}

interactive(){
    display_saved
    echo -ne "Enter an essid to connect: "
    local SSID
    read SSID
    connect ${SSID}
}

while getopts "hikls:" OPT ; do
    case ${OPT} in
        h)
            usage
            exit
            ;;
        i)
            ACTION=interactive
            ;;
        k)
            ACTION=kill_wifi
            ;;
        l)
            ACTION=display_saved
            ;;
        p)
            PATH_WPA=${OPTARG}
            ;;
        s)
            ARGS=${OPTARG}
            ACTION=connect
            ;;
        ?)
            usage
            exit
            ;;
    esac
done
shift $((OPTIND-1))

ACTION=${ACTION:-info}
${ACTION} ${ARGS}
