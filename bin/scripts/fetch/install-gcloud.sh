#!/bin/zsh

# Latest versions of GCLOUD can be found [here](https://cloud.google.com/sdk/docs/downloads-versioned-archives).
GCLOUD_FILENAME=google-cloud-cli-462.0.0-darwin-arm.tar.gz

if [ "$(uname -m)" = 'x86_64' ] ; then
  echo "🤖  Using Intel version of Google Cloud Utils"
  GCLOUD_FILENAME=google-cloud-cli-462.0.1-darwin-x86_64.tar.gz
else
  echo "🤖  Using Apple Silicon version of Google Cloud Utils"
fi

GCLOUD_URL="https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/${GCLOUD_FILENAME}"

PATH_TO_GCLOUD=$(command -v gcloud)
GCLOUD_DIR="$HOME"

if [ -f "${PATH_TO_GCLOUD}" ] ; then
  echo "✅  Google Cloud already installed"
  exit 0
fi

if [ -f "$HOME/Downloads/${GCLOUD_FILENAME}" ] ; then
  echo "Google cloud already downloaded"
else
  echo "Downloading gsutil"
  wget -P "$HOME/Downloads"  "$GCLOUD_URL"
fi

echo "Extracting gcloud archive to home directory"

tar -xzf "$HOME/Downloads/${GCLOUD_FILENAME}" -C "$GCLOUD_DIR"

cd "${GCLOUD_DIR}" || exit
./google-cloud-sdk/install.sh --install-python false --path-update true --command-completion true --bash-completion true --usage-reporting true --quiet

#Reload .zshrc file to get new configs added by google cloud
. "$HOME/.zshrc"