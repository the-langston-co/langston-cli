#!/bin/bash
cat banner.txt
echo "CLI version $(cat VERSION.txt)"
echo
echo

COMMAND=$1
PROGRAM=$2

if [[ $COMMAND == 'install' ]]; then
  if [[ $PROGRAM == 'auth-proxy' ]]; then
    echo "Running install Google Auth Proxy"
    ./scripts/auth-proxy/install.sh
  else
    echo "Program $PROGRAM not recognized. Unable to run install script."
  fi

else
  echo "Command $COMMAND not recognized"
fi

echo
echo