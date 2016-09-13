#!/bin/sh

SRCDIR=/usr/i686-w64-mingw32/sys-root/mingw/

#for f in bin/*; do echo $SRCDIR/$f; done
for f in bin/*; do cp $SRCDIR/$f $f; done
for f in lib/gstreamer-1.5/*; do cp $SRCDIR/$f $f; done
for f in lib/kurento/modules/*; do cp $SRCDIR/$f $f; done
