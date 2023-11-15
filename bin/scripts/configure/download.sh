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
  echo "installing homebrew"
  /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  echo "✅  Homebrew installed successfully"
fi

echo
echo "Downloading langston-cli..."
echo

RELEASES=$(curl -s --location 'https://api.github.com/repos/the-langston-co/langston-cli/releases')
DOWNLOAD_URL=$(jq -r ".[0].assets[0].browser_download_url" <<< "$RELEASES")
LATEST_VERSION=$(jq -r ".[0].tag_name" <<< "$RELEASES")
DOWNLOAD_FILENAME="langston-cli-${LATEST_VERSION}.tar.gz"
echo "downloading langston-cli archive from ${DOWNLOAD_URL}"
echo
curl -o "$DOWNLOAD_FILENAME" "$DOWNLOAD_URL"

echo "Langston CLI downloaded from "

if [ -f "${DOWNLOAD_FILENAME}" ] ; then
  echo "✅  Downloaded langston-cli to ${DOWNLOAD_DIR}/${DOWNLOAD_FILENAME}"
else
  echo "❌  Failed to save file. Exiting."
  exit 1
fi
echo "Extracting files to ${CLI_DIR}..."
tar -xzf "${DOWNLOAD_FILENAME}" -C ..

echo "Files extracted from archive. Contents of ~/langston-cli are:"
ls -la "${CLI_DIR}"