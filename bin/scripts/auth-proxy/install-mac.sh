#!/bin/zsh
autoload -Uz is-at-least
# Installs or upgrades cloud-sql-proxy in ~/langston-cli/bin to the version
# env.sh requires. An existing older binary is replaced.
source "$(dirname $0)/env.sh" prod

mkdir -p "${PROXY_BIN:h}"

INSTALLED=$("$PROXY_BIN" --version 2>/dev/null | sed -E 's/.*version ([0-9.]+).*/\1/')
if [[ -n "$INSTALLED" ]] && is-at-least "$REQUIRED_PROXY_VERSION" "$INSTALLED"; then
  echo "✅  cloud-sql-proxy $INSTALLED already installed"
  exit 0
fi

if [[ $(uname -m) == 'arm64' ]]; then
  ARCH=arm64
else
  ARCH=amd64
fi
echo "Installing cloud-sql-proxy v${REQUIRED_PROXY_VERSION} (${ARCH})${INSTALLED:+, replacing v$INSTALLED}"
URL="https://storage.googleapis.com/cloud-sql-connectors/cloud-sql-proxy/v${REQUIRED_PROXY_VERSION}/cloud-sql-proxy.darwin.${ARCH}"
# Download beside the target and move into place, so a running proxy keeps its
# binary and a failed download leaves the old one intact. The per-process name
# keeps concurrent installs from writing into the same file.
DOWNLOAD="$PROXY_BIN.download.$$"
if ! curl --fail --silent --show-error -o "$DOWNLOAD" "$URL"; then
  rm -f "$DOWNLOAD"
  echo "🛑  Download failed: $URL"
  exit 1
fi
chmod +x "$DOWNLOAD"
mv -f "$DOWNLOAD" "$PROXY_BIN"
echo "✅  $("$PROXY_BIN" --version)"
