#!/bin/sh
export DISPLAY=":1"

#Xvfb $DISPLAY -screen 0 800x600x16 -dpi 75 -nolisten tcp -audit 4 -ac -auth /root/.Xauthority 1>&2 2>/dev/null &
#x11vnc -display $DISPLAY -forever -nowf -xkb -rfbport 5901 1>&2 2>/dev/null &

R -f /tmp/installFromBiocViews.R
