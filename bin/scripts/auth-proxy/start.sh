#!/bin/zsh

SCRIPT_DIR=$(dirname $0)
source "$SCRIPT_DIR/env.sh" "${1:-prod}"
echo
echo "Starting auth proxy for env \"${ENV}\""

SERVICE_ACCOUNT_FILE="$HOME/langston-cli/auth/db-service-account-$KEY_ENV.json"

# Credential resolution. Two auth methods:
#   * Service-account key file (managed installs, e.g. Fetch desktop) — the
#     established path; keeps a stable, non-human DB identity + audit trail.
#   * Application Default Credentials (ADC) — you auth as yourself with
#     `gcloud auth application-default login`; nothing to download or rotate.
#     Preferred for engineers.
#
# Set LANGSTON_AUTH_ADC=1 to force ADC and ignore any key file. This is how an
# engineer switches to ADC without having to hunt down and delete a stale key,
# and is required to use ADC for prod/prod-replica (so those never *silently*
# change identity just because a managed key went missing).
if [[ ! -f "$SERVICE_ACCOUNT_FILE" ]]; then
  # Legacy location: earlier installs dropped the key at the langston-cli root.
  # Reuse the resolved filename (not raw $ENV) so the read-replica aliases
  # (`replica`/`analyst`, which map to db-service-account-prod.json) find the
  # legacy prod key instead of a nonexistent db-service-account-<alias>.json.
  SERVICE_ACCOUNT_FILE="$HOME/langston-cli/${SERVICE_ACCOUNT_FILE:t}"
fi

CRED_ARGS=()
if [[ "$LANGSTON_AUTH_ADC" == "1" ]]; then
  echo "   auth: Application Default Credentials (LANGSTON_AUTH_ADC=1; any key file ignored)"
elif [[ -f "$SERVICE_ACCOUNT_FILE" ]]; then
  echo "   auth: service account key ($SERVICE_ACCOUNT_FILE)"
  CRED_ARGS=(--credentials-file "$SERVICE_ACCOUNT_FILE")
elif [[ $ENV == 'stage' ]]; then
  # Stage is the engineer path; ADC is the intended default when no key exists.
  echo "   auth: Application Default Credentials (no key file found)"
  echo "         if the proxy fails to authenticate, run: gcloud auth application-default login"
else
  # prod / prod-replica: don't silently connect as a human identity. Require the
  # managed key, or opt in to ADC explicitly.
  echo "🛑  No service account key found for $ENV ($SERVICE_ACCOUNT_FILE)."
  echo "    Run \"langston auth $ENV\" to install the managed key, or set"
  echo "    LANGSTON_AUTH_ADC=1 to connect with your own identity (gcloud ADC)."
  exit 1
fi


echo "Starting instanceName $INSTANCE_NAME on port $DB_PORT"
echo "   Admin Port: ${ADMIN_PORT}"
echo "   HTTP Port: ${HTTP_PORT}"
echo

# Check if already running. A running proxy whose tunnel no longer reaches
# Cloud SQL is replaced rather than reported as fine.
if [ "$(proxy_http "$HTTP_PORT" liveness)" -eq 200 ]; then
  if proxy_probe 5; then
    echo "✅  cloud-sql-proxy for '$NICKNAME' is already running"
    echo "You can stop it by running \"langston db stop ${ENV}\""
    exit
  fi
  echo "⚠️  cloud-sql-proxy for '$NICKNAME' is running but not serving connections; replacing it"
  "$SCRIPT_DIR/stop.sh" "$ENV"
  echo
fi

# Installs or upgrades the proxy when it is missing or older than required;
# a no-op otherwise.
zsh "$SCRIPT_DIR/install-mac.sh" || exit 1

# Run cloud sql proxy in background. CRED_ARGS is empty when using ADC, which
# makes cloud-sql-proxy use Application Default Credentials. Output goes to a
# log (not /dev/null) so failures are diagnosable.
# Keep the previous run's log: it is the evidence of why a proxy went bad.
[[ -f "$PROXY_LOG" ]] && mv -f "$PROXY_LOG" "$PROXY_LOG.1"
# --lazy-refresh fetches certificates when a connection needs one instead of on
# a background timer that stalls while the laptop sleeps.
PROXY_ARGS=(--port "$DB_PORT" "$INSTANCE_NAME" "${CRED_ARGS[@]}" --lazy-refresh --quitquitquit --health-check --http-port "$HTTP_PORT" --admin-port "$ADMIN_PORT")
echo "running: $PROXY_BIN ${PROXY_ARGS[*]} (log: $PROXY_LOG)"
nohup "$PROXY_BIN" "${PROXY_ARGS[@]}" &> "$PROXY_LOG" &
PROXY_PID=$!

# Verify the proxy actually serves connections before reporting success. A
# backgrounded proxy with a stale key or missing/unauthorized ADC still
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
    echo "    The key file may be stale or revoked — delete it and retry, or set LANGSTON_AUTH_ADC=1 to use your own identity (gcloud ADC)."
  else
    echo "    Check your credentials: run \"gcloud auth application-default login\" and confirm your access to $ENV."
  fi
  exit 1
fi

echo
echo "You can stop it by running \"langston db stop ${ENV}\""
echo "✅  cloud-sql-proxy started for '$NICKNAME'"
