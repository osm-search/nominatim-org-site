#!/bin/bash

SRCDIR=$1
VERSION=$2

DESTDIR=$PWD/release-docs/$VERSION

if [ -d $DESTDIR ]; then
    rm -f $DESTDIR/*md
else
    mkdir $DESTDIR
fi



pushd $SRCDIR

for fl in *md; do
    BASENAME=${fl/.md/}
    cat > $DESTDIR/$fl << MDHEAD
---
layout: page
parmalink: /docs/$VERSION/$BASENAME
---
MDHEAD

    cat $fl >> $DESTDIR/$fl

done

popd

