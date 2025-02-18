#!/bin/bash

##
# Invoke this script and provide it a single argument of what file to parse.
# The file should be a fail2ban.log file.  It will write some files to /tmp/,
# produce a little bit of output to stderr, and then if everything is working,
# a new file should show up in the current directory named attacks.svg (unless
# you change the EXT variable way down below, in which case it will produce a
# jpg, png, or whatever else you tell it.)
#

##
# This script uses the following commands (package):
#  * geoiplookup (geoip-bin)
#  * gnuplot (gnuplot-x11)
# and possibly others... (wc, sort, ...)

##
# Dies if the provided command is not in the path
die_without() {
	if ! which "$1" &>/dev/null; then
		echo "This script requires the $1 command to run." >&2
		exit 1
	fi
}

die_without geoiplookup
die_without gnuplot

if [ "$#" -eq 0 ]; then
	LOGFILE="/var/log/fail2ban.log"
else
	LOGFILE="$1"
fi

echo "Using $LOGFILE as log file..." >&2

##
# Parses an input file and produces a list of origin countries for any IP
# addresses found.
#    @param LOGFILE The file that will be parsed for IP addresses.
#    @return Returns a list of "IP: CC, Country of Origin" lines.
produce_countries() {
	local LOGFILE="${1}"
	grep -o -E '(([0-9]+)\.){3}[0-9]+' "${LOGFILE}" | sort -u | while read -r IP; do
		echo "Looking up info for $IP..." >&2
		INFO=$(geoiplookup "${IP}")
		echo "${INFO}" | head -n 1 >&2
		if echo "${INFO}" | grep "not found" 2>/dev/null 1>/dev/null; then
			echo "Unable to find ${IP}" >&2
			echo "${IP}: 00, **unknown**"
			continue
		fi
		INFO=$(echo "${INFO}" | head -n 1 | cut -f2 -d:)
		echo "${IP}:${INFO}"
	done
}

##
# Parses an input file of "IP: CC, Country of Origin" and produces
# a summary of "CC: count" lines.
#   @param INFILE The file that will be parsed for country IP and Country
#          Codes.
#   @return Returns a list of CC: count lines.
produce_counts() {
	local INFILE="${1}"
	cut -f2- -d, "${INFILE}" |
		cut -f2 -d: |
		sort -u |
		while read -r LINE; do
			(
				echo "${LINE}:"
				grep -c "${LINE}" "${INFILE}"
			) | xargs
		done
}

##
# Create a temporary file for multiply processing input
t="$(mktemp)"
produce_countries "${LOGFILE}" >"${t}"

##
# Create a summary file that includes country: count
produce_counts "${t}" >"${t}".summary

##
# Sort it for use later in a graph
sort -r -t: -g -k2 "${t}".summary >"${t}".sorted

##
# Produce output that can be ingested via gnuplot
while read -r LINE; do
	echo "\"$(echo "${LINE}" | cut -f1 -d:)\" $(echo "${LINE}" | cut -f2 -d:)"
done >"${t}.data" <"${t}".sorted

##
# Width of the output image will be based on number of countries*25
WIDTH=$(wc -l "${t}".summary | awk '{print $1}')
WIDTH=$((WIDTH * 27))

##
# Height will depend on number of attacks * 3
ATTACKS="$(wc -l "${t}" | awk '{print $1}')"
if [ "${ATTACKS}" -lt 100 ]; then
	HEIGHT=640
else
	HEIGHT=$((ATTACKS * 3))
fi

##
# Produce an svg (also valid to make it png)
EXT="svg"

##
# Build a simple gnuplot script that generates file output
(
	echo "set terminal ${EXT} size ${WIDTH},${HEIGHT} fname 'Verdana'"
	echo "set output \"${t}.${EXT}\""
	echo "set style fill solid"
	echo "set key off"
	echo "set xtics rotate"
	echo "set ylabel \"Number of Attacks\""
	echo "set xlabel \"Country of Origin\""
	echo "set yrange [ 0 : * ]"
	echo "plot \"${t}.data\" using 2: xtic(1) with histogram"
) >"${t}".plot
gnuplot "${t}".plot

if [ -f "${t}"."${EXT}" ]; then
	mv "${t}"."${EXT}" attacks."${EXT}"
	echo "Produced attacks.${EXT} file." >&2
	rm "${t}"
	rm "${t}".summary
	rm "${t}".data
	mv "${t}".sorted attacks.sorted
	rm "${t}".plot
else
	echo "Failed to produce output file... missing something?" >&2
	echo "Leaving files behind for debugging: ${t}, ${t}.sorted, ${t}.data, ${t}.plot" >&2
fi
