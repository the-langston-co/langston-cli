#!/usr/bin/env zsh

CURRENT_DIR=$(dirname $0)
RESOURCES_DIR="$CURRENT_DIR"/../../../resources

echo
echo "Checking for updates..."

RELEASES=$(curl -s --location 'https://api.github.com/repos/the-langston-co/langston-cli/releases')
LATEST_VERSION=$(jq -r ".[0].tag_name" <<< "$RELEASES")
CURRENT_VERSION=$(cat "$RESOURCES_DIR/VERSION.txt")


DOWNLOAD_URL=$(jq -r ".[0].assets[0].browser_download_url" <<< "$RELEASES")

if [ "$CURRENT_VERSION" = "$LATEST_VERSION" ]; then
  echo "✅  You are running the latest version ($LATEST_VERSION)"
  exit
else
  echo "⭐️ An update is available! "
  echo "---------------------------"
  echo "✔️  Current\t$CURRENT_VERSION"
  echo "✨  Latest \t$LATEST_VERSION"
  echo "---------------------------"
  echo " Download $LATEST_VERSION here: $DOWNLOAD_URL"
fi


read -p "Install the new version now (Y/n)? " -n 1 -r
echo    # (optional) move to a new line
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo Not installing
    [[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1 # handle exits from shell or function but don't exit interactive shell
fi

. "${CURRENT_DIR}/download.sh"