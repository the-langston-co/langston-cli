#!/bin/zsh

ENV=${1:='prod'}
DB_PORT=3307
HTTP_PORT=9050
ADMIN_PORT=9051
NICKNAME=$ENV
echo
echo "Starting auth proxy for env \"${ENV}\""

SERVICE_ACCOUNT_FILE="$HOME/langston-cli/auth/db-service-account-$ENV.json"
INSTANCE_NAME=prod-instance

if [[ $ENV == 'stage' ]]; then
  INSTANCE_NAME='langston-stage:us-central1:langston-db-dev'
  DB_PORT=3306
  HTTP_PORT=9090
  ADMIN_PORT=9091
  NICKNAME=stage
elif [[ $ENV == 'prod-replica' || $ENV == 'replica' || $ENV == 'analyst' ]]; then
  SERVICE_ACCOUNT_FILE="$HOME/langston-cli/auth/db-service-account-prod.json"
  INSTANCE_NAME='langston-prod:us-central1:langston-prod-replica'
  DB_PORT=3308
  HTTP_PORT=9060
  ADMIN_PORT=9061
  NICKNAME='prod (read-replica)'
elif [[ $ENV == 'prod' ]]; then
  INSTANCE_NAME='langston-prod:us-central1:langston-prod'
  DB_PORT=3307
  HTTP_PORT=9050
  ADMIN_PORT=9051
  NICKNAME='prod'
fi

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

# Check if already running
LIVENESS_URL="http://localhost:${HTTP_PORT}/liveness"
LIVENESS_CODE=$(curl --silent --output /dev/null --write-out "%{http_code}" -X POST $LIVENESS_URL)

if [ "$LIVENESS_CODE" -eq 200 ]; then
  echo "✅  cloud-sql-proxy for '$NICKNAME' is already running"
  echo "You can stop it by running \"langston auth-proxy stop\""
  exit
fi

# Run cloud sql proxy in background. CRED_ARGS is empty when using ADC, which
# makes cloud-sql-proxy use Application Default Credentials. Output goes to a
# log (not /dev/null) so failures are diagnosable.
PROXY_LOG="${TMPDIR:-/tmp}/langston-auth-proxy-${ENV}.log"
echo "running: cloud-sql-proxy --port $DB_PORT $INSTANCE_NAME ${CRED_ARGS[*]} --quitquitquit --health-check --http-port $HTTP_PORT --admin-port $ADMIN_PORT (log: $PROXY_LOG)"
cloud-sql-proxy --port $DB_PORT "$INSTANCE_NAME" "${CRED_ARGS[@]}" --quitquitquit --health-check --http-port "$HTTP_PORT" --admin-port "$ADMIN_PORT" &> "$PROXY_LOG" &
PROXY_PID=$!

# Verify the proxy actually became ready before reporting success. A
# backgrounded proxy with a stale key or missing/unauthorized ADC still
# "launches" and then fails every connection — readiness (creds valid +
# instance reachable) is the real signal.
READINESS_URL="http://localhost:${HTTP_PORT}/readiness"
READY=""
for i in {1..15}; do
  kill -0 "$PROXY_PID" 2>/dev/null || break   # proxy process exited
  CODE=$(curl --silent --output /dev/null --write-out "%{http_code}" -X POST "$READINESS_URL")
  if [ "$CODE" -eq 200 ]; then READY=1; break; fi
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
echo "You can stop it by running \"langston auth-proxy stop\""
echo "✅  cloud-sql-proxy started for '$NICKNAME'"
