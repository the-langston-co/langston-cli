#!/bin/zsh


echo "Getting status of cloud-sql-proxy server..."
# Check if already running
BASE_URL=http://localhost:9090
LIVENESS_CODE=$(curl --silent --output /dev/null --write-out "%{http_code}" -X POST $BASE_URL/liveness)
STARTUP_CODE=$(curl --silent --output /dev/null --write-out "%{http_code}" -X POST $BASE_URL/startup)
READINESS_CODE=$(curl --silent --output /dev/null --write-out "%{http_code}" -X POST $BASE_URL/readiness)




if [ "$LIVENESS_CODE" -eq 200 ]; then
  echo "✅  liveness OK"
else
  echo "🛑 liveness FAILED"
fi

if [ "$READINESS_CODE" -eq 200 ]; then
  echo "✅  readiness OK"
else
  echo "🛑 readiness FAILED"
fi

if [ "$STARTUP_CODE" -eq 200 ]; then
  echo "✅  startup OK"
else
  echo "🛑 startup FAILED"
fi

echo
echo "Stop cloud-sql-proxy by running \"langston auth-proxy stop\""
echo "Start cloud-sql-proxy by running \"langston auth-proxy start\""