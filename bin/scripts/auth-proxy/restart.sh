#!/bin/zsh
# Restart the proxy for one target. The shared per-target lock serializes it
# with other sessions' start/stop/restart; a caller that waited re-checks the
# tunnel and skips its own restart when the other session already fixed it.
SCRIPT_DIR=$(dirname $0)
source "$SCRIPT_DIR/env.sh" "${1:-prod}"
lock_target

if [[ -n "$LOCK_WAITED" ]] && proxy_probe 5; then
  echo "✅  cloud-sql-proxy for '$NICKNAME' was restarted by another session and is healthy"
  exit 0
fi

"$SCRIPT_DIR/stop.sh" "$ENV"
echo
"$SCRIPT_DIR/start.sh" "$ENV"
