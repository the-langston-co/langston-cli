#!/bin/zsh
echo "Installing Google Auth Proxy"
if [[ $OSTYPE == 'darwin'* ]]; then
  sh $(dirname $0)/install-mac.sh
else
  sh $(dirname $0)/install-windows.sh
fi

