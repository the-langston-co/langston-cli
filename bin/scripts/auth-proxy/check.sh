#!/bin/zsh
# Exits 0 only when the proxy is running AND a connection through it reaches
# Cloud SQL. /readiness alone can report 200 while every connection fails
# (e.g. an expired certificate after sleep), so the tunnel probe decides.
source "$(dirname $0)/env.sh" "${1:-prod}"

echo "[${ENV}] Getting db status from http://localhost:${HTTP_PORT}..."

LIVENESS_CODE=$(proxy_http "$HTTP_PORT" liveness)
READINESS_CODE=$(proxy_http "$HTTP_PORT" readiness)

if [ "$LIVENESS_CODE" -eq 200 ]; then
  echo "✅  ${ENV} liveness OK"
else
  echo "🛑 ${ENV} liveness FAILED. Response code: \"${LIVENESS_CODE}\""
fi

if [ "$READINESS_CODE" -eq 200 ]; then
  echo "✅  ${ENV} readiness OK"
else
  echo "🛑 ${ENV} readiness FAILED. Response code: \"${READINESS_CODE}\""
fi

if proxy_probe 5; then
  echo "✅  ${ENV} tunnel OK (port ${DB_PORT} reaches Cloud SQL)"
  exit 0
fi

echo "🛑 ${ENV} tunnel FAILED: port ${DB_PORT} did not reach Cloud SQL"
if [[ -n "$(proxy_pids)" ]]; then
  echo "The proxy is running but not serving connections. Fix it with \"langston db restart ${ENV}\""
else
  echo "Start cloud-sql-proxy by running \"langston db start ${ENV}\""
fi
exit 1
