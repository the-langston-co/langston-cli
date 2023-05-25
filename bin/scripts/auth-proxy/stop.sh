#!/bin/zsh

PORT=9091
ADMIN_URL="http://localhost:$PORT/quitquitquit"
STATUS_CODE=$(curl --silent --output /dev/stderr --write-out "%{http_code}" -X POST $ADMIN_URL)

if [ "$STATUS_CODE" -eq 200 ]; then
  echo "✅  cloud-sql-proxy stopped"
else
  echo "⃠  cloud-sql-proxy is not running"
fi