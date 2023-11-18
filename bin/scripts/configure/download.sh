#!/usr/bin/env sh

# This script downloads & installs the cli. If the cli is already installed, it will update it to the latest version.
# This is also the source of the script in Kandji to install langston-cli automatically

CLI_DIR="$HOME/langston-cli"
DOWNLOAD_DIR="$CLI_DIR/downloads"
mkdir -p "${DOWNLOAD_DIR}"
cd "${DOWNLOAD_DIR}" || exit


#First, ensure homebrew is installed

BREW_PATH=$(which brew)
if [ -x "$BREW_PATH" ] ; then
  echo "✅  Homebrew is already installed"
else
  echo "'brew' was not found via 'which brew'...installing homebrew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if [ -x "$BREW_PATH" ] ; then
    echo "✅  Homebrew installed successfully"
  else
    echo "❌  Failed to install homebrew"
    exit 1
  fi
fi

PATH_TO_JQ=$(which jq)
if [ -x "$PATH_TO_JQ" ] ; then
  echo "✅  jq already installed"
else
  echo "installing JQ..."
#  echo "Please enter the password to your computer to perform the installation"
  brew install jq
  PATH_TO_JQ=$(which jq)
  if [ -x "$PATH_TO_JQ" ] ; then
    echo "✅  jq installed successfully"
  fi
fi

PATH_TO_JQ=$(which jq)
if ! [ -x "$PATH_TO_JQ" ] ; then
  echo "❌  jq is not installed, can not continue."
  exit 1
fi

PATH_TO_WGET=$(which wget)
if [ -x "$PATH_TO_WGET" ] ; then
  echo "✅  wget installed"
else
  echo "installing wget..."
#  echo "Please enter the password to your computer to perform the installation"
  brew install wget
  PATH_TO_WGET=$(which wget)
  echo
  echo "✅  wget installed"
fi

PATH_TO_WGET=$(which wget)
if ! [ -x "$PATH_TO_WGET" ] ; then
  echo "❌  wget is not installed, can not continue."
  exit 1
fi

RELEASES=$(curl -s --location 'https://api.github.com/repos/the-langston-co/langston-cli/releases')
DOWNLOAD_URL=$(jq -r ".[0].assets[0].browser_download_url" <<< "$RELEASES")
LATEST_VERSION=$(jq -r ".[0].tag_name" <<< "$RELEASES")
DOWNLOAD_FILENAME="langston-cli-${LATEST_VERSION}.tar.gz"
echo
echo "⏳  Downloading langston-cli from ${DOWNLOAD_URL}..."
echo
wget -O "$DOWNLOAD_FILENAME" "$DOWNLOAD_URL"

echo "Langston CLI downloaded from "

if [ -f "${DOWNLOAD_FILENAME}" ] ; then
  echo "✅  Downloaded langston-cli to ${DOWNLOAD_DIR}/${DOWNLOAD_FILENAME}"
  echo
else
  echo "❌  Failed to save file. Exiting."
  exit 1
fi
echo "Extracting files to ${CLI_DIR}..."
tar -xzvf "${DOWNLOAD_FILENAME}" -C ..

echo "🎉  Langston CLI setup finished."