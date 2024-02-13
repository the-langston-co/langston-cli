#!/bin/zsh

mkdir -p dist
SRC="$HOME/langston-fetch/dist"

#FILENAME="Fetch.dmg"
FILENAME=$(ls "$SRC" | tail -n 1)
#FILENAME=$(find "$SRC"  -type f | tail -n 1)
echo "Using file $FILENAME"
#hdiutil create -volname "Fetch" -srcfolder "$SRC"  -ov -format UDZO "dist/$FILENAME"