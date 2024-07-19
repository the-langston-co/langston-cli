#!/bin/zsh
ENV=${1:='prod'}

echo "Attempting to stop auth-proxy for ${ENV}"

PORT=9051
if [[ $ENV == 'stage' ]]; then
  PORT=9091
elif [[ $ENV == 'prod' ]]; then
  PORT=9051
elif [[ $ENV == 'prod-replica' ]]; then
  PORT=9061
fi

ADMIN_URL="http://localhost:$PORT/quitquitquit"
STATUS_CODE=$(curl --silent --output /dev/stderr --write-out "%{http_code}" -X POST $ADMIN_URL)

echo "  POST to ${ADMIN_URL} returned status \"${STATUS_CODE}\""
echo
if [ "$STATUS_CODE" -eq 200 ]; then
  echo "✅  cloud-sql-proxy stopped"
else
  echo "⃠  cloud-sql-proxy is not running"
fi