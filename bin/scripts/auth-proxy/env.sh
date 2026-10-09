#!/bin/zsh
# Shared target resolution and health probes for the auth-proxy scripts.
# Source it with the requested env name as $1:
#   source "$(dirname $0)/env.sh" "$1"
# Sets ENV (canonical name), INSTANCE_NAME, DB_PORT, HTTP_PORT, ADMIN_PORT,
# NICKNAME, KEY_ENV, PROXY_BIN, PROXY_LOG and LOCK_FILE.

# The proxy version start.sh requires. install-mac.sh upgrades anything older.
# v2.26.0 brings --lazy-refresh: certificates are fetched on demand instead of
# by a background timer, which stalls while a laptop sleeps and leaves the
# proxy "ready" but serving an expired certificate ("tls: bad certificate").
REQUIRED_PROXY_VERSION='2.26.0'
PROXY_BIN="$HOME/langston-cli/bin/cloud-sql-proxy"

case "${1:-prod}" in
  stage)
    ENV='stage'
    INSTANCE_NAME='langston-stage:us-central1:langston-db-dev'
    DB_PORT=3306
    HTTP_PORT=9090
    ADMIN_PORT=9091
    NICKNAME='stage'
    KEY_ENV='stage'
    ;;
  prod-replica|replica|analyst)
    ENV='prod-replica'
    INSTANCE_NAME='langston-prod:us-central1:langston-prod-replica'
    DB_PORT=3308
    HTTP_PORT=9060
    ADMIN_PORT=9061
    NICKNAME='prod (read-replica)'
    KEY_ENV='prod'
    ;;
  prod)
    ENV='prod'
    INSTANCE_NAME='langston-prod:us-central1:langston-prod'
    DB_PORT=3307
    HTTP_PORT=9050
    ADMIN_PORT=9051
    NICKNAME='prod'
    KEY_ENV='prod'
    ;;
  *)
    echo "🛑  Unknown db target \"$1\". Use one of: stage, prod, prod-replica (aliases: replica, analyst)."
    exit 1
    ;;
esac

PROXY_LOG="${TMPDIR:-/tmp}/langston-auth-proxy-${ENV}.log"
LOCK_FILE="${TMPDIR:-/tmp}/langston-auth-proxy-${ENV}.lockfile"

# Take the per-target lock that start, stop and restart share, so concurrent
# sessions never stop or launch the same proxy at once. It is a kernel lock
# (fcntl via zsystem flock), released when this process exits however it exits,
# so there is no stale lock to reclaim. Nested calls (restart -> stop/start)
# inherit LANGSTON_DB_LOCK_HELD and do not lock again. Sets LOCK_WAITED=1 when
# another session held the lock first.
LOCK_WAITED=''
lock_target() {
  [[ "$LANGSTON_DB_LOCK_HELD" == "$ENV" ]] && return 0
  zmodload zsh/system || exit 1
  touch "$LOCK_FILE"
  if ! zsystem flock -t 0 -f LOCK_FD "$LOCK_FILE" 2>/dev/null; then
    LOCK_WAITED=1
    echo "Waiting for another session's start/stop/restart of ${ENV}..."
    # Long enough for a restart that downloads a new proxy binary.
    if ! zsystem flock -t 180 -f LOCK_FD "$LOCK_FILE"; then
      echo "🛑  Timed out waiting for another session's start/stop/restart of ${ENV}"
      exit 1
    fi
  fi
  export LANGSTON_DB_LOCK_HELD="$ENV"
}

# POST to a proxy health/admin endpoint and print the HTTP status code.
# --max-time matters: a wedged proxy accepts the connection and never answers.
proxy_http() {
  curl --silent --output /dev/null --max-time 3 --write-out "%{http_code}" -X POST "http://localhost:$1/$2"
}

# End-to-end, credential-free probe through the tunnel. Sends a Postgres
# SSLRequest and waits for the one-byte reply ('N' or 'S'). The proxy only
# dials Cloud SQL when a client connects, so this exercises the certificate and
# the upstream connection — the part /readiness does not check. Returns 0 when
# a reply arrives within $1 seconds (default 5).
proxy_probe() {
  local timeout=${1:-5}
  local fd reply=''
  zmodload zsh/net/tcp || return 1
  ztcp 127.0.0.1 "$DB_PORT" 2>/dev/null || return 1
  fd=$REPLY
  print -n -u "$fd" '\x00\x00\x00\x08\x04\xd2\x16\x2f' 2>/dev/null
  read -t "$timeout" -k 1 -u "$fd" reply 2>/dev/null
  ztcp -c "$fd" 2>/dev/null
  [[ "$reply" == 'N' || "$reply" == 'S' ]]
}

# PIDs of the proxy process serving this target, matched on its health port.
proxy_pids() {
  pgrep -f "cloud-sql-proxy .*--http-port ${HTTP_PORT}( |$)"
}
