#!/bin/bash
# Empty contents of the dist folder
rm -rf dist

# Create dist/ folder if it doesn't exist
mkdir -p dist
VERSION=$(cat resources/VERSION.txt | tr -d " \t\n\r")
PROPOSED_VERSION=$1
VERSION_REGEX="^v(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$"
echo "proposed version \"$PROPOSED_VERSION\""

if [ -z "$PROPOSED_VERSION" ]; then
  echo "No version provided, using current version of $VERSION"
elif [[ "$PROPOSED_VERSION" =~ ${VERSION_REGEX} ]]; then
  echo "Setting version to \"$PROPOSED_VERSION\""
  VERSION=$PROPOSED_VERSION
#  echo -n "$PROPOSED_VERSION" > resources/VERSION.txt
else
  echo "Invalid version provided: \"$PROPOSED_VERSION\". Must match semversion format of vX.X.X. Notice the \"v\" at the beginning. All values for \"X\" must be numeric"
  exit 1
fi

if git tag "$VERSION" ; then
  echo "Successfully created Git tag $VERSION"
else
  exit 1
fi

echo -n "$VERSION" > resources/VERSION.txt

echo "Creating bundle for version $VERSION"

# Bundle the contents as a tarball, excluding files & folders listed in `.archiveignore`
tar -zcf "dist/langston-cli-$VERSION.tar.gz" --exclude-from=".archiveignore" .

echo "Bundle created at: dist/langston-cli-$VERSION.tar.gz"