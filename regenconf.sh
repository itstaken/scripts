#!/bin/bash

##
# Script for regenerating my conky config file.
# Generates a config that contains the following:
#
#  * Battery percent (on my chromebooK)
#  * Wifi ESSID (again, on my chromebook)
#  * the ip address of the wifi NIC
#  * a network graph
#  * additional NICs will display ip address and graph
#
# TODO: add arguments
#
# The resulting config displays something like this:
#
#   Battery: 76%
#   Wifi: attwifi
#
#   mlan0: up, addr 192.168.1.2
#   Up                      Down
#   ┌─────────────┬─────────────┐
#   │      ╱╲     │             │
#   │┄┄┄╱╲╱┄┄╲┄┄┄ │┄┄┄╱╲╱╲╱╲┄┄┄ │
#   └─────────────┴─────────────┘
#
#   eth0: up, addr 192.168.2.2
#   Up                      Down
#   ┌─────────────┬─────────────┐
#   │             │             │
#   │┄┄┄╱╲╱╲╱╲┄┄┄┄│┄┄┄╱╲╱╲╱╲┄┄┄ │
#   └─────────────┴─────────────┘
#


echo TEXT

##
# IF the system uses battery...
battery.sh &>/dev/null
if [ $? -eq 0 ] ; then
cat << "EOF_battery"
Battery: ${color green}${execi 60 battery.sh}${color white}
EOF_battery
fi

##
# If the system uses wifi... and has my wifi script
wifi=$(iwconfig 2>/dev/null | grep ESSID:)
if [ $? -eq 0 ] ; then
    wifi=$(echo $wifi | awk '{print $1}')
    wifi.sh -e &> /dev/null
    if [ $? -eq 0 ] ; then
        cat << EOF_wifi
\${if_up ${wifi}}
Wifi: \${color red}\${execi 30 wifi.sh -e}\${color white}
\${endif}
EOF_wifi
    fi
fi

##
# Enumerate all devices and create an etnry for them...
while read -r -d $'\n' ETHER; do
ifconfig "${ETHER}" | grep 'Link' | grep -v 'Local Loopback' &> /dev/null
if [ "$?" -eq 0 ] ; then
cat << EOF_eth
\${if_up ${ETHER}}
${ETHER}: up, addr \$alignr \${addr ${ETHER}}
Up \${alignr} Down
\${upspeed ${ETHER}}\${alignr}\${downspeed ${ETHER}}
\${upspeedgraph ${ETHER} 50,100 006600 00ff00}\${alignr}\${downspeedgraph ${ETHER} 50,100 006600 00ff00}
\${else}
${ETHER}: down
\${endif}
EOF_eth
fi

done < <(ifconfig -a | grep Ethernet | awk '{print $1}')
