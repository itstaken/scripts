#!/bin/bash

##
# This script will set the backlight brightness, provided that the permissions
# on the files are set appropriately.
# Invoke without arguments to see the current brightness.
#
# To ensure that the permissions are correct, add the following rule to udev,
# possibly in a file named /etc/udev/rules.d/99-backlight.rules:

# ACTION=="add", KERNEL=="pwm-backlight", SUBSYSTEM=="backlight", RUN+="/bin/chmod 0666 /sys/devices/soc0/pwm-backlight/backlight/pwm-backlight/brightness
# ACTION=="add", KERNEL=="pwm-backlight", SUBSYSTEM=="backlight", RUN+="/bin/chgrp users /sys/devices/soc0/pwm-backlight/backlight/pwm-backlight/brightness

PATH_BACKLIGHT=/sys/class/backlight/pwm-backlight
PATH_BRIGHTNESS=${PATH_BACKLIGHT}/brightness
PATH_MAX_BRIGHTNESS=${PATH_BACKLIGHT}/max_brightness

##
# Displays the usage for the script on stdout.
usage(){
    cat << "EOF"
This script allows controlling the brightness on the CB5-311.

Call it with the following options:
  -h - help  - display this help
  -u - up    - increase the brightness
  -d - down  - decrease the brightness
  -s value   - set the brightness to value

Calling it without arguments displays the current brightness and exits.

EOF
}

##
# Gets the current brightness, echoed on stdout.
get_brightness(){
    cat "${PATH_BRIGHTNESS}"
}

##
# Gets the max brightness, echoed on stdout.
get_max_brightness(){
    cat "${PATH_MAX_BRIGHTNESS}"
}

##
# Sets the current brightness to the provided value.
#   @param brighness Integer value between 0 and max_brightness
set_brightness(){
    local NEW=$1
    local MAX=$(get_max_brightness)

    if [ "${NEW}" -ge 0 ] ; then
        if [ "${NEW}" -lt "${MAX}" ] ; then
            echo "${NEW}" > "${PATH_BRIGHTNESS}"
        fi
    fi
}

##
# Turn the brightness up by one point.
brightness_up(){
    local OLD=$(get_brightness)
    local MAX=$(get_max_brightness)
    local NEW=$((OLD+1))

    if [ "${NEW}" -gt "${MAX}" ] ; then
        NEW="${MAX}"
    fi

    set_brightness "${NEW}"
}

##
# Turn the brightness down by one point.
brightness_down(){
    local OLD=$(get_brightness)
    local NEW=$((OLD-1))

    if [ "${NEW}" -lt 0 ] ; then
        NEW=0
    fi

    set_brightness "${NEW}"
}

while getopts "huds:" OPT ; do
    case "${OPT}" in
        h)
            usage
            exit
            ;;
        u)
            brightness_up
            exit
            ;;
        d)
            brightness_down
            exit
            ;;

        s)
            set_brightness "$OPTARG"
            exit
            ;;
        ?)
            usage
            exit
            ;;
    esac
done
shift $((OPTIND-1))

echo "$(get_brightness)" / "$(get_max_brightness)"
