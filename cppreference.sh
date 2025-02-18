#!/bin/bash

##
# This script tries to convert an offline archive of cppreference.com into a
# browseable mardown version.
# This script cannot just be executed and expected to work, some setup is
# required, first:
#   1) Go here and download the link for the raw tar.gz version: 
#        http://en.cppreference.com/w/Cppreference:Archives
#   2) Edit this script and set RAW_IMAGE equal to the entire file name
#   3) Install pandoc if it's not installed
#   4) Run this script.
#

#Now enter that file name here:
RAW_IMAGE=cppreference-doc-20140323.tar.gz
LOCAL_NAME=${RAW_IMAGE%.tar.gz}/reference/en.cppreference.com/w/

OUTPUT=helpdocs

if [ ! -d ${LOCAL_NAME} ] ; then
    echo "Extracting ${RAW_IMAGE}..."
    tar xf ${RAW_IMAGE} ${LOCAL_NAME} ||
        (echo "Failed to extract, did you download it and update the script?" &&
        exit -1)
fi

if [ ! -d ${OUTPUT} ] ; then
    mkdir ${OUTPUT}
    #generate markdown from inputs...
    echo "Generating markdown from html files..." &&
    find ${LOCAL_NAME} -iname '*.html' | while read file 
    do
        outfile=${file/.html/.mkd}
#        echo OUTFILE: ${outfile}
#        echo command: pandoc -r html -t markdown ${file} -o ${outfile} 
        pandoc -r html -t markdown ${file} -o ${outfile} &&
        rm ${file} &&
        #update links
        sed -i 's/\(\.[Hh][Tt][Mm][Ll]\)/.mkd/g' ${outfile} &&
        #remove useless search
        sed -ni '1h;1!H;${;g;s/#* Search.*\(^#* Namespaces\)/\1/g;p}' ${outfile} && 
        #strip view menus && 
        sed -ni '1h;1!H;${;g;s/#* Views.*\(^#* Actions\)/\1/g;p}' ${outfile} && 
        #condense section heading links && 
        sed -i 's/\(^#*\) \[\[.*\](.*)]/\1/g' ${outfile} && 
        #strip edit links && 
        sed -i 's/\[\[edit\].*action=edit)//g' ${outfile} && 
        #stripping navigation links && 
        sed -ni '1h;1!H;${;g;s/#* Navigation.*//g;p}' ${outfile} && 
        #strip leading spaces from lines with only links && 
        sed -i 's/^ \[/[/g' ${outfile} && 
        #strip newlines from links && 
        sed -ni '1h;1!H;${;g;s/\([A-Za-z0-9]\+\)\n\([A-Za-z0-9]\+\)/\1 \2/g;p}' ${outfile} && 
        #remove alt text from links
        sed -i 's/ "\([A-Za-z/+. ]\)\+")/)/g' ${outfile}
        #move to output && 
        cp --parents ${outfile} ${OUTPUT} ||
        exit -1
    done 
    if [ "$?" -ne 0 ] ; then
        exit -1
    fi

    echo "Re-basing output..." &&
    mv ${OUTPUT}/${LOCAL_NAME}/* ${OUTPUT} &&
    echo "Removing old content..." &&
    rm -rf ${LOCAL_NAME} &&
    rm -rf ${OUTPUT}/${LOCAL_NAME} &&
    echo "Maybe it worked... done."
fi
