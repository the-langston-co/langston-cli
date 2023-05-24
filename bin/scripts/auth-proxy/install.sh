#!/bin/zsh

if [[ $OSTYPE == 'darwin'* ]]; then
  sh $(dirname $0)/install-mac.sh
else
  sh $(dirname $0)/install-windows.sh
fi

