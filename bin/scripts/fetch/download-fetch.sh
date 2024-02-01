#!/bin/zsh
parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" || exit ; pwd -P )
cd "$parent_path" || exit 1
echo "Fetch current dir: $(dirname $0)"
echo "Fetch parent_path: ${parent_path}"
"$parent_path/scripts/fetch/install-gcloud.sh" || exit 1
"$parent_path/scripts/fetch/auth-gcloud.sh" || exit 1

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
rm -rf tmp
unzip -q "$FETCH_ROOT/downloads/${ZIP_FILENAME}" -d tmp

rm -rf R;
mv tmp/R R
rm -rf tmp

echo
echo "✅  Successfully installed version ${VERSION} of Fetch"