#!/bin/zsh

GCLOUD_FILENAME=google-cloud-cli-462.0.0-darwin-arm.tar.gz
GCLOUD_URL="https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/${GCLOUD_FILENAME}"

PATH_TO_GCLOUD=$(command -v gcloud)
GCLOUD_DIR=~

if [ -f "${PATH_TO_GCLOUD}" ] ; then
  echo "✅  Google Cloud already installed"
  exit 0
fi

if [ -f ~/Downloads/"${GCLOUD_FILENAME}" ] ; then
  echo "Google cloud already downloaded"
else
  echo "Downloading gsutil"
  wget -P ~/Downloads  "$GCLOUD_URL"
fi

echo "Extracting gcloud archive to home directory"

tar -xzf ~/Downloads/"${GCLOUD_FILENAME}" -C "$GCLOUD_DIR"

cd "${GCLOUD_DIR}" || exit
./google-cloud-sdk/install.sh --install-python false --path-update true --command-completion true --bash-completion true --usage-reporting true --quiet

