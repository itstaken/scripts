#!/bin/bash

##
# This is one of my CB5-311 (Chromebook 13) scripts.

##
# This script will fetch information about the battery.
# Currently it just displays the current charge percent.
# I haven't decided what other details would be useful.

POWER_SUPPLY_CLASS=/sys/class/power_supply/
HAPPY=1
if [ -d ${POWER_SUPPLY_CLASS} ] ; then
    for f in ${POWER_SUPPLY_CLASS}/* ; do
        CAPACITY_PATH=${f}/capacity
        if [ -f "${CAPACITY_PATH}" ] ; then
            cat "${CAPACITY_PATH}"
            HAPPY=0
        fi
    done
fi

exit ${HAPPY}
