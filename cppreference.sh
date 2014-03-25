#!/bin/bash

# Go here and coy the link for the raw version: http://en.cppreference.com/w/Cppreference:Archives
#Now enter that file name here:
RAW_IMAGE=cppreference-doc-20140323.tar.gz
LOCAL_NAME=${RAW_IMAGE%.tar.gz}/reference/en.cppreference.com/w/

OUTPUT=helpdocs

if [ ! -d ${LOCAL_NAME} ] ; then
    tar xf ${RAW_IMAGE} ${LOCAL_NAME}
fi

if [ ! -d ${OUTPUT} ] ; then
    mkdir ${OUTPUT}
    #generate markdown from inputs...
    echo "Generating markdown from html files..." &&
    find ${LOCAL_NAME} -iname '*.html' -exec pandoc -r html -t markdown {} -o {}.mkd \; &&
    #remove original inputs &&
    echo "Deleting original html files..." &&
    find ${LOCAL_NAME} -iname '*.html' -delete &&
    #update links to point to new mkd files &&
    echo "Updating links to point to other .mkd files so gf works..." &&
    find ${LOCAL_NAME} -iname '*.mkd' -exec sed -i 's/\(\.[Hh][Tt][Mm][Ll]\)/\1.mkd/g' {} \; &&
    #condense some section headings... &&
    echo "Stripping useless search options" &&
    find ${LOCAL_NAME} -iname '*.mkd' -exec sed -ni '1h;1!H;${;g;s/#* Search.*\(^#* Namespaces\)/\1/g;p}' {} \; &&
    echo "Stripping view menus" &&
    find ${LOCAL_NAME} -iname '*.mkd' -exec sed -ni '1h;1!H;${;g;s/#* Views.*\(^#* Actions\)/\1/g;p}' {} \; &&
    echo "Condensing section heading links..." &&
    find ${LOCAL_NAME} -iname '*.mkd' -exec sed -i 's/\(^#*\) \[\[.*\](.*)]/\1/g' {} \; &&
    echo "Stripping edit links" &&
    find ${LOCAL_NAME} -iname '*.mkd' -exec sed -i 's/\[\[edit\].*action=edit)//g' {} \; &&
    echo "Stripping navigation links..." &&
    find ${LOCAL_NAME} -iname '*.mkd' -exec sed -ni '1h;1!H;${;g;s/#* Navigation.*//g;p}' {} \;  &&
    echo "Stripping leading spaces from lines with only links..." &&
    find ${LOCAL_NAME} -iname '*.mkd' -exec sed -i 's/^ \[/[/g' {} \; &&
    echo "Stripping newlines from links" &&
    find ${LOCAL_NAME} -iname '*.mkd' -exec sed -ni '1h;1!H;${;g;s/\([A-Za-z0-9]\+\)\n\([A-Za-z0-9]\+\)/\1 \2/g;p}' {} \; &&
    echo "Moving mkd files to output..." &&
    find ${LOCAL_NAME}/reference/en.cppreference.com/w/ -iname '*.mkd' -exec cp --parents {} ${OUTPUT} \; &&
    mv ${OUTPUT}/${LOCAL_NAME}/reference/en.cppreference.com/w/* ${OUTPUT} &&
    echo "Removing old content..." &&
    rm -rf ${LOCAL_NAME} &&
    rm -rf ${OUTPUT}/${LOCAL_NAME} &&
    echo "Maybe it worked... done."
fi
