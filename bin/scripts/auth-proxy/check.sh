#!/bin/zsh
ENV=${1:='prod'}

HTTP_PORT=9090
if [[ $ENV == 'stage' ]]; then
  HTTP_PORT=9090
elif [[ $ENV == 'prod' ]]; then
    HTTP_PORT=9050
fi

# Check if already running
BASE_URL="http://localhost:${HTTP_PORT}"
LIVENESS_CODE=$(curl --silent --output /dev/null --write-out "%{http_code}" -X POST $BASE_URL/liveness)
STARTUP_CODE=$(curl --silent --output /dev/null --write-out "%{http_code}" -X POST $BASE_URL/startup)
READINESS_CODE=$(curl --silent --output /dev/null --write-out "%{http_code}" -X POST $BASE_URL/readiness)

echo "[${ENV}] Getting db status from ${BASE_URL}..."

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

if [ "$STARTUP_CODE" -eq 200 ]; then
  echo "✅  ${ENV} startup OK"
else
  echo "🛑 ${ENV} startup FAILED. Response code: \"${STARTUP_CODE}\""
fi

if [ "$LIVENESS_CODE" -eq 200 ]; then
  echo "Stop cloud-sql-proxy by running \"langston db stop ${ENV}\""
else
  echo "Start cloud-sql-proxy by running \"langston db start ${ENV}\""
fi