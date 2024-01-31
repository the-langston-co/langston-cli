#!/bin/zsh

chmod +x install-gcloud.sh
chmod +x auth-gcloud.sh

./install-gcloud.sh || exit 1
./auth-gcloud.sh || exit 1

echo "Finding latest version of Fetch in Google Cloud Storage"
FETCH_ROOT="$HOME/langston-fetch"
LATEST_FILE=$(gcloud storage ls 'gs://langston-fetch/releases/v*.zip' | sort -k2n | tail -n1)
echo "Latest Fetch release is: $LATEST_FILE"

mkdir -p "${FETCH_ROOT}/downloads"

ZIP_FILENAME=$(basename "$LATEST_FILE")
gcloud storage cp "${LATEST_FILE}" "${FETCH_ROOT}/downloads"


cd "${FETCH_ROOT}" || exit 1

VERSION="$(basename "$ZIP_FILENAME" .zip)"
echo "$VERSION" > version.txt
unzip "$FETCH_ROOT/downloads/${ZIP_FILENAME}" -d R-tmp

rm -rf R;
mv R-tmp/R R
rm -rf R-tmp