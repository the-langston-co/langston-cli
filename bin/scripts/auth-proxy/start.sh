#!/bin/zsh

SCRIPT_DIR=$(dirname $0)
source "$SCRIPT_DIR/../configure/google-auth.sh"
parse_db_arguments "$@"
source "$SCRIPT_DIR/env.sh" "${DB_TARGET:-prod}"
# Before the lock: other sessions' start, stop and restart of this target wait
# on it, and must not wait on a browser. The sign-in is checked again below,
# under the lock.
renew_google_sign_in || exit 1
# Held through the check, any replacement, and the launch.
lock_target
echo
echo "Starting auth proxy for env \"${ENV}\""

SERVICE_ACCOUNT_FILE="$HOME/langston-cli/auth/db-service-account-$KEY_ENV.json"
if [[ ! -f "$SERVICE_ACCOUNT_FILE" ]]; then
  # Legacy location: earlier installs dropped the key at the langston-cli root.
  # Reuse the resolved filename (not raw $ENV) so the read-replica aliases
  # (`replica`/`analyst`, which map to db-service-account-prod.json) find the
  # legacy prod key instead of a nonexistent db-service-account-<alias>.json.
  SERVICE_ACCOUNT_FILE="$HOME/langston-cli/${SERVICE_ACCOUNT_FILE:t}"
fi

# Credential resolution, in order:
#   1. The Google sign-in on this machine (`langston login`). The proxy reaches
#      Cloud SQL as that person. For the targets Fetch uses it also logs in to
#      Postgres as them (--auto-iam-authn), so Fetch needs no database
#      password. Password logins for built-in users (postgres, analyst) keep
#      working through the same proxy.
#   2. A service-account key file, on machines that have not signed in yet.
#      It keeps Fetch releases that still log in with a password working until
#      they are replaced. `langston login` no longer installs this file.
#
# LANGSTON_AUTH_ADC=1 skips the key file even when the sign-in has expired, so
# the proxy never falls back to the shared identity for someone who chose their own.
CRED_ARGS=()
GOOGLE_LOGIN_ARGS=()
if google_signed_in; then
  echo "   auth: your Google sign-in"
  if [[ -n "$GOOGLE_DB_LOGIN" ]]; then
    GOOGLE_LOGIN_ARGS=(--auto-iam-authn)
  fi
  PROXY_IDENTITY="google:$(credential_fingerprint "$(google_credentials_file)"):${GOOGLE_LOGIN_ARGS[*]}"
elif [[ "$LANGSTON_AUTH_ADC" != "1" && -f "$SERVICE_ACCOUNT_FILE" ]]; then
  echo "   auth: service account key ($SERVICE_ACCOUNT_FILE)"
  CRED_ARGS=(--credentials-file "$SERVICE_ACCOUNT_FILE")
  PROXY_IDENTITY="key:$(credential_fingerprint "$SERVICE_ACCOUNT_FILE")"
else
  echo "🛑  You are not signed in to Google, or the sign-in has expired."
  echo "    Run \"langston login\", then \"langston db start ${ENV}\" again,"
  echo "    or run \"langston db start ${ENV} --login\" to do both."
  exit 1
fi


echo "Starting instanceName $INSTANCE_NAME on port $DB_PORT"
echo "   Admin Port: ${ADMIN_PORT}"
echo "   HTTP Port: ${HTTP_PORT}"
echo

# Check if already running. A running proxy whose tunnel no longer reaches
# Cloud SQL is replaced rather than reported as fine.
# Keyed on the process, not /liveness: a frozen proxy answers neither but
# still holds the ports.
if [[ -n "$(proxy_pids)" ]]; then
  if ! proxy_has_identity "$PROXY_IDENTITY"; then
    # Started with a key file, as another account, or before this machine
    # signed in: it would connect as someone other than the sign-in above.
    echo "⚠️  cloud-sql-proxy for '$NICKNAME' is running with a different sign-in; replacing it"
  elif proxy_probe 5; then
    echo "✅  cloud-sql-proxy for '$NICKNAME' is already running"
    echo "You can stop it by running \"langston db stop ${ENV}\""
    exit
  else
    echo "⚠️  cloud-sql-proxy for '$NICKNAME' is running but not serving connections; replacing it"
  fi
  "$SCRIPT_DIR/stop.sh" "$ENV"
  echo
fi

# Installs or upgrades the proxy when it is missing or older than required;
# a no-op otherwise.
zsh "$SCRIPT_DIR/install-mac.sh" || exit 1

# Run cloud sql proxy in background. CRED_ARGS is empty when using the Google
# sign-in, which cloud-sql-proxy finds on its own. Output goes to a log (not
# /dev/null) so failures are diagnosable.
# Keep the previous run's log: it is the evidence of why a proxy went bad.
[[ -f "$PROXY_LOG" ]] && mv -f "$PROXY_LOG" "$PROXY_LOG.1"
# --lazy-refresh fetches certificates when a connection needs one instead of on
# a background timer that stalls while the laptop sleeps.
PROXY_ARGS=(--port "$DB_PORT" "$INSTANCE_NAME" "${CRED_ARGS[@]}" "${GOOGLE_LOGIN_ARGS[@]}" --lazy-refresh --quitquitquit --health-check --http-port "$HTTP_PORT" --admin-port "$ADMIN_PORT")
echo "running: $PROXY_BIN ${PROXY_ARGS[*]} (log: $PROXY_LOG)"
nohup "$PROXY_BIN" "${PROXY_ARGS[@]}" &> "$PROXY_LOG" &
PROXY_PID=$!

# Verify the proxy actually serves connections before reporting success. A
# backgrounded proxy with a stale key or an unauthorized Google account still
# "launches" and then fails every connection, so require /readiness and a
# probe through the tunnel.
READY=""
for i in {1..15}; do
  kill -0 "$PROXY_PID" 2>/dev/null || break   # proxy process exited
  if [ "$(proxy_http "$HTTP_PORT" readiness)" -eq 200 ] && proxy_probe 5; then READY=1; break; fi
  sleep 1
done

if [ -z "$READY" ]; then
  echo
  echo "🛑  cloud-sql-proxy for '$NICKNAME' failed to become ready."
  kill "$PROXY_PID" 2>/dev/null
  echo "    Recent proxy log ($PROXY_LOG):"
  tail -n 5 "$PROXY_LOG" 2>/dev/null | sed 's/^/      /'
  if [ ${#CRED_ARGS} -gt 0 ]; then
    echo "    The key file may be stale or revoked. Run \"langston login\" to connect as yourself instead."
  else
    echo "    Run \"langston login --force\" and try again. If it still fails, your Google account may not have access to $ENV: ask Engineering."
  fi
  exit 1
fi

print -r -l -- "$PROXY_PID" "$PROXY_IDENTITY" > "$PROXY_IDENTITY_FILE"

echo
echo "You can stop it by running \"langston db stop ${ENV}\""
echo "✅  cloud-sql-proxy started for '$NICKNAME'"
