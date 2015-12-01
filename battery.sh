#!/bin/bash

##
# This is one of my CB5-311 (Chromebook 13) scripts.

##
# This script will fetch information about the battery.
# Currently it just displays the current charge percent.
# I haven't decided what other details would be useful.

POWER_SUPPLY_CLASS=/sys/class/power_supply/
HAPPY=1
if [ -d "${POWER_SUPPLY_CLASS}" ] ; then
#    COUNT=$(ls "${POWER_SUPPLY_CLASS}" | wc -l)
    for f in "${POWER_SUPPLY_CLASS}"/* ; do
        TYPE_PATH=${f}/type
        CAPACITY_PATH=${f}/capacity
        NAME_PATH=${f}/device/name
        STATUS_PATH=${f}/status
        HEALTH_PATH=${f}/health
        PRESENT_PATH=${f}/present
        if [ -f "${PRESENT_PATH}" ] ; then
            PRESENT=$(cat "${PRESENT_PATH}")
        else
            PRESENT=0
        fi
        if [ -f "${CAPACITY_PATH}" ] ; then
            CAPACITY=$(cat "${CAPACITY_PATH}")
            TYPE=$(cat "${TYPE_PATH}")
            NAME=$(cat "${NAME_PATH}")
            STATUS=$(cat "${STATUS_PATH}")
            HEALTH=$(cat "${HEALTH_PATH}")
            if [ "${HEALTH}" != "Good" ] ; then
                echo "[${NAME}] ${CAPACITY}% (${HEALTH})"
            else
                if [ "${PRESENT}" -ne 1 ] ; then
                    echo "[${NAME}] Missing"
                else
                    echo "[${NAME}] ${CAPACITY}% (${STATUS})"
                fi
            fi
            HAPPY=0
        fi
    done
fi

exit ${HAPPY}
