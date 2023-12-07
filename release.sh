#!/usr/bin/env zsh

VERSION=$(cat resources/VERSION.txt | tr -d " \t\n\r")
PROPOSED_VERSION=$1
VERSION_REGEX="^v(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$"
op plugin inspect gh
GH_TOKEN=$(op item get qwzdc2tyxqv3sdpkpkx47ckd6e --fields token)
export GH_TOKEN
gh auth status


if [ -z "$PROPOSED_VERSION" ]; then
  echo "No version provided, using current version of $VERSION"
elif [[ "$PROPOSED_VERSION" =~ ${VERSION_REGEX} ]]; then
  echo "Setting version to \"$PROPOSED_VERSION\""
  VERSION=$PROPOSED_VERSION
#  echo -n "$PROPOSED_VERSION" > resources/VERSION.txt
else
  echo "❌  Invalid version provided: \"$PROPOSED_VERSION\". Must match semversion format of vX.X.X. Notice the \"v\" at the beginning. All values for \"X\" must be numeric"
  exit 1
fi

echo
echo "Creating new GitHub release for version ${VERSION}..."

./bundle.sh "${VERSION}"


gh release create "${VERSION}" "dist/langston-cli-$VERSION.tar.gz" --generate-notes