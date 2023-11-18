#!/usr/bin/env sh
BREW_CMD=$(command -v brew)
echo "BREW_CMD=${BREW_CMD}"
if [[ $(command -v brew) == "" ]]; then
  echo "❌  Home brew is not installed, can not continue"
  exit 1
else
  echo "Home brew is installed"
fi

BREW_PATH=$(command -v brew)
echo "BREW_PATH=${BREW_PATH}"
if [ -x "$BREW_PATH" ] ; then
  echo "✅  $(brew -v) is already installed"
else
  echo "-x ${BREW_PATH} not installed"
fi