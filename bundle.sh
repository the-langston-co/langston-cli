#!/bin/zsh
# Empty contents of the dist folder
rm -rf dist

# Create dist/ folder if it doesn't exist
mkdir -p dist
VERSION=$(cat resources/VERSION.txt | tr -d " \t\n\r")
PROPOSED_VERSION=$1
VERSION_REGEX="^v(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$"

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

echo -n "$VERSION" > resources/VERSION.txt

git add resources/VERSION.txt
git commit -m"'Update version to $VERSION'"

# The tarball is built from HEAD, so HEAD must carry the new version. This
# also allows re-running when the version commit already exists (nothing to
# commit) while stopping a release whose commit failed (e.g. a hook).
if [[ "$(git show HEAD:resources/VERSION.txt | tr -d " \t\n\r")" != "$VERSION" ]]; then
  echo "❌  HEAD's resources/VERSION.txt is not $VERSION; the version commit failed. Not tagging or bundling."
  exit 1
fi

if git tag "$VERSION" &> /dev/null ; then
  echo "Successfully created Git tag $VERSION"
else
  echo "Tag ${VERSION} already exists!"
fi
git push origin
git push origin --tags
echo
# Bundle the committed tree (HEAD, which now carries the version bump) as a
# tarball, excluding paths listed in `.archiveignore`. Archiving HEAD rather
# than the working directory keeps untracked files out of the public release:
# tarring `.` once shipped an untracked kandji/fetch/upload/.env.
STAGING=$(mktemp -d)
trap 'rm -rf "$STAGING"' EXIT
git archive --format=tar HEAD | tar -x -C "$STAGING" || exit 1
tar -zcf "dist/langston-cli-$VERSION.tar.gz" --exclude-from=".archiveignore" -C "$STAGING" . || exit 1

echo "Release artifact created at ./dist/langston-cli-$VERSION.tar.gz"
