#!/bin/bash

##
# This is one of my CB5-311 (Chromebook 13) scripts.

##
# This script will fetch information about the battery.
# Currently it just displays the current charge percent.
# I haven't decided what other details would be useful.

PATH_BATTERY=/sys/class/power_supply/sbs-5-000b/
PATH_BATTERY_CAPACITY=${PATH_BATTERY}/capacity

#
cat ${PATH_BATTERY_CAPACITY}
