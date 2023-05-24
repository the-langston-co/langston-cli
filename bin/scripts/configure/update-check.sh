#!/bin/zsh

CURRENT_DIR=$(dirname $0)
RESOURCES_DIR="$CURRENT_DIR"/../../../resources

echo
echo "Checking for updates..."
echo
RELEASES=$(curl -s --location 'https://api.github.com/repos/the-langston-co/langston-cli/releases')
LATEST_VERSION=$(jq -r ".[0].tag_name" <<< "$RELEASES")
CURRENT_VERSION=$(cat "$RESOURCES_DIR/VERSION.txt")


DOWNLOAD_URL=$(jq -r ".[0].assets[0].browser_download_url" <<< "$RELEASES")

if [ "$CURRENT_VERSION" = "$LATEST_VERSION" ]; then
  echo "✅  You are running the latest version ($LATEST_VERSION)"
else
  echo "⭐️ An update is available! "
  echo "---------------------------"
  echo -e " Current\t$CURRENT_VERSION"
  echo -e " Latest \t$LATEST_VERSION"
  echo "---------------------------"
  echo " Download $LATEST_VERSION here: $DOWNLOAD_URL"
fi