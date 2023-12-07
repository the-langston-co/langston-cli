#!/bin/zsh

# This script downloads & installs the cli. If the cli is already installed, it will update it to the latest version.
# This is also the source of the script in Kandji to install langston-cli automatically

CLI_DIR="$HOME/langston-cli"
DOWNLOAD_DIR="$CLI_DIR/downloads"
mkdir -p "${DOWNLOAD_DIR}"
cd "${DOWNLOAD_DIR}" || exit

echo "*********************************************"
echo "* LANGSTON DOWNLOAD SCRIPT STARTING         *"
echo "*********************************************"
echo
echo "Running as: whoami=$(whoami)"

#First, ensure homebrew is installed

BREW_PATH=$(command -v brew)
if [ -x "$BREW_PATH" ] ; then
  echo "✅  $(brew -v) is already installed"
else
  echo "'brew' was not found... installing homebrew"
  NONINTERACTIVE=1 /bin/zsh -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  BREW_PATH=$(command -v brew)
  if [ -x "$BREW_PATH" ] ; then
    echo "✅  $(brew -v) installed successfully"
  else
    echo "❌  Failed to install homebrew"
    exit 1
  fi
fi

if [[ $(command -v brew) == "" ]]; then
  echo "❌  Home brew is not installed, can not continue"
  exit 1
else
  echo "Home brew is installed"
fi

PATH_TO_JQ=$(command -v jq)
if [ -x "$PATH_TO_JQ" ] ; then
  echo "✅  jq already installed ($(jq --version))"
else
  echo "installing JQ..."
#  echo "Please enter the password to your computer to perform the installation"
  brew install jq
  PATH_TO_JQ=$(command -v jq)
  if [ -x "$PATH_TO_JQ" ] ; then
    echo "✅  jq installed successfully ($(jq --version))"
  fi
fi

PATH_TO_JQ=$(command -v jq)
if ! [ -x "$PATH_TO_JQ" ] ; then
  echo "❌  jq is not installed, can not continue."
  exit 1
fi

PATH_TO_WGET=$(command -v wget)
if [ -x "$PATH_TO_WGET" ] ; then
  echo "✅  wget installed"
else
  echo "installing wget..."
#  echo "Please enter the password to your computer to perform the installation"
  brew install wget
  PATH_TO_WGET=$(command -v wget)
  echo
  echo "✅  wget installed"
fi

PATH_TO_WGET=$(command -v wget)
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