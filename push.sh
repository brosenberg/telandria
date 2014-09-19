#!/bin/sh

srcdir=/home/brosenberg/website/newsite
dstdir=/usr/share/nginx/www/

if [ "$1" != "-f" ]; then
    echo -n "Are you sure you want to push? (y/N) > "
    read response
    if [ "$response" != "y" ]; then
        echo "Aborting..."
        exit
    fi
else
    echo "Forcing push..."
fi

cd $srcdir
for src in `find -iname \*.html`; do
    echo "$srcdir/$src -> $dstdir/$src" | sed 's@/./@/@g;s@//*@/@g'
    cp --parents -p $src $dstdir
done
