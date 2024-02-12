#!/bin/zsh

mkdir -p dist
SRC="$HOME/langston-fetch/dist"
FILENAME="Fetch-1-1-0.dmg"
hdiutil create -volname "Fetch" -srcfolder "$SRC"  -ov -format UDZO "dist/$FILENAME"
#mv $FILENAME dist