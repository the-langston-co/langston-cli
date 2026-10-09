#!/bin/zsh
# Restart the proxy for one target, serialized by a lock so several agent
# sessions that hit the same broken proxy at once trigger one restart, not a
# race for the same ports. A caller that waited on another restart re-checks
# the tunnel and skips its own restart when the other one fixed it.
SCRIPT_DIR=$(dirname $0)
source "$SCRIPT_DIR/env.sh" "${1:-prod}"

acquire_lock() {
  local waited=0
  until mkdir "$LOCK_DIR" 2>/dev/null; do
    # A restart takes ~20s at most; a lock older than 2 minutes is abandoned.
    if [[ -n $(find "$LOCK_DIR" -maxdepth 0 -mmin +2 2>/dev/null) ]]; then
      rmdir "$LOCK_DIR" 2>/dev/null
      continue
    fi
    if (( waited >= 60 )); then
      echo "🛑  Timed out waiting for another restart of ${ENV} (lock: $LOCK_DIR)"
      exit 1
    fi
    WAITED_ON_OTHER=1
    sleep 1
    (( waited++ ))
  done
}

WAITED_ON_OTHER=''
acquire_lock
# Set at top level: in zsh an EXIT trap set inside a function fires when that
# function returns, which would release the lock immediately.
trap 'rmdir "$LOCK_DIR" 2>/dev/null' EXIT

if [[ -n "$WAITED_ON_OTHER" ]] && proxy_probe 5; then
  echo "✅  cloud-sql-proxy for '$NICKNAME' was restarted by another session and is healthy"
  exit 0
fi

"$SCRIPT_DIR/stop.sh" "$ENV"
echo
"$SCRIPT_DIR/start.sh" "$ENV"
