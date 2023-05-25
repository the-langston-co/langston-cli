#!/bin/zsh

ENV=${1:='prod'}
PORT=3306
echo
echo "Starting auth proxy for env \"${ENV}\""

INSTANCE_NAME=prod-instance
if [[ $ENV == 'stage' ]]; then
  INSTANCE_NAME=langston-stage:us-central1:langston-db-dev
else
  echo "⚠️ Prod database is not yet supported. Exiting."
  exit
fi

# TODO: Use credentials file with service account

echo "Using instanceName $INSTANCE_NAME on port $PORT"
echo

# Check if already running
LIVENESS_URL=http://localhost:9090/liveness
LIVENESS_CODE=$(curl --silent --output /dev/null --write-out "%{http_code}" -X POST $LIVENESS_URL)

if [ "$LIVENESS_CODE" -eq 200 ]; then
  echo "✅  cloud-sql-proxy is already running"
  echo "You can stop it by running \"langston auth-proxy stop\""
  exit
fi

# Run cloud sql proxy in background.
cloud-sql-proxy --port $PORT "$INSTANCE_NAME" --gcloud-auth --quitquitquit --health-check &> /dev/null &

echo
echo "✅  cloud-sql-proxy started!"
echo "You can stop it by running \"langston auth-proxy stop\""