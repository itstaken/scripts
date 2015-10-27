#!/bin/bash

##
# Script for regenerating my conkyconf file.
# Generates a battery meter at the top (on my chromebooK)
# a line displaying the wifi access point (again, on my chromebook)
# the ip address of the wifi nic
# a graph of network traffic on the wifi nic
#
# TODO: add wired networks

echo TEXT

##
# IF the system uses battery...
battery.sh 2>&1 >/dev/null
if [ $? -eq 0 ] ; then
cat << "EOF_battery"
Battery: ${color green}${execi 60 battery.sh}${color white}%
EOF_battery
fi

##
# If the system uses wifi...
wifi=$(iwconfig 2>/dev/null | grep ESSID: | awk '{print $1}')
if [ $? -eq 0 ] ; then
cat << EOF_wifi
\${if_up ${wifi}}
Wifi: \${color red}\${execi 30 wifi.sh -e}\${color white}
${wifi}: up, addr \$alignr \${addr ${wifi}}
Up \${alignr} Down
\${upspeed ${wifi}}\${alignr}\${downspeed ${wifi}}
\${upspeedgraph ${wifi} 50,100 006600 00ff00}\${alignr}\${downspeedgraph ${wifi} 50,100 006600 00ff00}
\${else}
${wifi}: down
\${endif}
EOF_wifi
fi
