#!/bin/bash

##
# This is one of my CB5-311 (Chromebook 13) scripts.

##
# This script will enable or disable the touchpad by using xinput.
# On my laptop, device 6 is the touchpad.
#
# Unfortunately, I don't know how to get the current state of the device, so I
# have to use a file.  I assume that the first time the script is called, the
# device is enabled.

STATE_FILE=/tmp/.touchpad-state
DEVICE_NO=6

##
# Returns 0 when enabled, 1 if disabled.
get_state(){
    local STATE=0
    if [ -f "${STATE_FILE}" ] ; then
        STATE=$(awk '{print $1}' "${STATE_FILE}")
        if [ "${STATE}" -ne 1 ] ; then
            STATE=0
        fi
    fi
    return "${STATE}"
}

##
# Sets the state file content to the provided value
set_state(){
    local VALUE="$1"
    echo "${VALUE}" > "${STATE_FILE}"
}

##
# Displays the usage for the script on stdout.
usage(){
    cat << "EOF"
This script enables or disables the touchpad on the CB5-311.

Call it with the following options:
  -h - help  - display this help

Calling it without arguments will toggle (either enable or disable) the
touchpad under X11.

EOF
}

while getopts "h" OPT ; do
    case ${OPT} in
        h)
            usage
            exit
            ;;
    esac
done
shift $((OPTIND-1))

get_state
if [ "$?" -eq 0 ] ; then
    xinput --disable "${DEVICE_NO}"
    set_state 1
else
    xinput --enable "${DEVICE_NO}"
    set_state 0
fi
