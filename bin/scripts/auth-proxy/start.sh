#!/bin/zsh

ENV=${1:='prod'}
DB_PORT=3307
HTTP_PORT=9050
ADMIN_PORT=9051

echo
echo "Starting auth proxy for env \"${ENV}\""

SERVICE_ACCOUNT_FILE="$HOME/langston-cli/db-service-account-$ENV.json"

if [[ ! -f "$SERVICE_ACCOUNT_FILE" ]]; then
  echo "🛑  No service account file found for $ENV ($SERVICE_ACCOUNT_FILE). You may need to run \"langston auth $ENV\" to configure the necessary credentials."
  exit 1
fi

INSTANCE_NAME=prod-instance
if [[ $ENV == 'stage' ]]; then
  INSTANCE_NAME=langston-stage:us-central1:langston-db-dev
  DB_PORT=3306
  HTTP_PORT=9090
  ADMIN_PORT=9091
elif [[ $ENV == 'prod' ]]; then
  INSTANCE_NAME=langston-prod:us-central1:langston-prod
  DB_PORT=3307
  HTTP_PORT=9050
  ADMIN_PORT=9051
fi

echo "Starting instanceName $INSTANCE_NAME on port $DB_PORT"
echo "   Admin Port: ${ADMIN_PORT}"
echo "   HTTP Port: ${HTTP_PORT}"
echo

# Check if already running
LIVENESS_URL="http://localhost:${HTTP_PORT}/liveness"
LIVENESS_CODE=$(curl --silent --output /dev/null --write-out "%{http_code}" -X POST $LIVENESS_URL)

if [ "$LIVENESS_CODE" -eq 200 ]; then
  echo "✅  cloud-sql-proxy is already running"
  echo "You can stop it by running \"langston auth-proxy stop\""
  exit
fi

# Run cloud sql proxy in background.
echo "running: cloud-sql-proxy --port $DB_PORT $INSTANCE_NAME --credentials-file $SERVICE_ACCOUNT_FILE --quitquitquit --health-check --http-port $HTTP_PORT --admin-port $ADMIN_PORT &> /dev/null &"
cloud-sql-proxy --port $DB_PORT "$INSTANCE_NAME" --credentials-file "$SERVICE_ACCOUNT_FILE" --quitquitquit --health-check --http-port "$HTTP_PORT" --admin-port "$ADMIN_PORT" &> /dev/null &

echo
echo "✅  cloud-sql-proxy started!"
echo "You can stop it by running \"langston auth-proxy stop\""