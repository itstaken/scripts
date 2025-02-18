#!/bin/bash

##
# This script tries to convert an offline archive of cppreference.com into a
# browseable markdown version.
# This script cannot just be executed and expected to work, some setup is
# required, first:
#   1) Go here and download the link for the raw tar.xz version:
#        http://en.cppreference.com/w/Cppreference:Archives
#   2) Edit this script and set RAW_IMAGE equal to the entire file name
#   3) Install pandoc if it's not installed
#   4) Run this script.
#

set -x
#Now enter that file name here:
RAW_IMAGE=cppreference-doc-20190607.tar.xz
LOCAL_NAME="${RAW_IMAGE%.tar.xz}"/reference/en.cppreference.com/w/

#https://en.cppreference.com/w/File:cppreference-doc-20190607.tar.xz

OUTPUT=helpdocs

if [ ! -f "${RAW_IMAGE}" ]; then
	echo "Didn't find ${RAW_IMAGE}.  Trying to download it..."
	if ! wget http://upload.cppreference.com/mwiki/images/8/80/"${RAW_IMAGE}"; then
		echo "Failed to download, bailing..."
		exit 1
	fi
fi

if [ ! -d "${LOCAL_NAME}" ]; then
	echo "Extracting ${RAW_IMAGE}..."
	if ! tar xf "${RAW_IMAGE}" "${LOCAL_NAME}"; then
		echo "Failed to extract, probably the automatically fetched file 404'd"
		echo "and instead of a tar.gz, there's a text file containing an error"
		echo "To fix the problem, manually download the file and try again."
		exit 2
	fi
fi

if [ ! -d "${OUTPUT}" ]; then
	mkdir "${OUTPUT}"
	#generate markdown from inputs...
	echo "Generating markdown from html files..." &&
		find "${LOCAL_NAME}" -iname '*.html' | while read -r file; do
			outfile="${file/.html/.md}"
			pandoc -f html -t gfm-raw_html "${file}" -o "${outfile}" &&
			rm "${file}" &&
				#update links
				sed -i 's/\(\.[Hh][Tt][Mm][Ll]\)/.md/g' "${outfile}" &&
				#remove useless search
				sed -ni '1h;1!H;${;g;s/#* Search.*\(^#* Namespaces\)/\1/g;p}' "${outfile}" &&
				#strip view menus &&
				sed -ni '1h;1!H;${;g;s/#* Views.*\(^#* Actions\)/\1/g;p}' "${outfile}" &&
				#condense section heading links &&
				sed -i 's/\(^#*\) \[\[.*\](.*)]/\1/g' "${outfile}" &&
				#strip edit links &&
				sed -i 's/\[\[edit\].*action=edit)//g' "${outfile}" &&
				#stripping navigation links &&
				sed -ni '1h;1!H;${;g;s/#* Navigation.*//g;p}' "${outfile}" &&
				#strip leading spaces from lines with only links &&
				sed -i 's/^ \[/[/g' "${outfile}" &&
				#strip newlines from links &&
				sed -ni '1h;1!H;${;g;s/\([A-Za-z0-9]\+\)\n\([A-Za-z0-9]\+\)/\1 \2/g;p}' "${outfile}" &&
				#remove alt text from links
				sed -i 's/ "\([][A-Za-z/+.: ]\+\)")/)/g' "${outfile}"
			#remove heading styles
			sed -i 's/ {#\([A-Za-z0-9]\+\) \.\1}//g' "${outfile}"
			#move to output &&
			cp --parents "${outfile}" "${OUTPUT}" ||
				exit 3
		done

	echo "Re-basing output..." &&
		mv "${OUTPUT}"/"${LOCAL_NAME}"/* "${OUTPUT}" &&
		echo "Removing old content..." &&
		rm -rf "${LOCAL_NAME}" &&
		rm -rf "${OUTPUT:?}"/"${LOCAL_NAME}" &&
		echo "Maybe it worked... done."
else
	echo "The ${OUTPUT} directory existed, remove it if you're sure you want" \
		"to continue."
fi
