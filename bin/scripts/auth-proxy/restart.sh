#!/bin/zsh
# Restart the proxy for one target. The shared per-target lock serializes it
# with other sessions' start/stop/restart; a caller that waited re-checks the
# tunnel and skips its own restart when the other session already fixed it.
SCRIPT_DIR=$(dirname $0)
source "$SCRIPT_DIR/../configure/google-auth.sh"
parse_db_arguments "$@"
source "$SCRIPT_DIR/env.sh" "${DB_TARGET:-prod}"
lock_target

if [[ -n "$LOCK_WAITED" ]] && proxy_probe 5; then
  echo "✅  cloud-sql-proxy for '$NICKNAME' was restarted by another session and is healthy"
  exit 0
fi

# Renew an expired Google sign-in before stopping anything: a restart that
# stops the proxy and then cannot start it leaves the person with no
# connection at all.
if ! google_signed_in && google_sign_in_allowed; then
  echo "Your Google sign-in is missing or has expired. Signing in again..."
  "$SCRIPT_DIR/../configure/auth.sh" || exit 1
fi

"$SCRIPT_DIR/stop.sh" "$ENV"
echo
"$SCRIPT_DIR/start.sh" "$ENV"
