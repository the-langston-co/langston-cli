#!/bin/zsh

ENV=${1:='prod'}
echo
echo "🔑 Please enter the service account password ($ENV):"

read -r PASSWORD

echo
echo -e "🔒 Got it! Downloading the $ENV service account file..."

HOST="https://api.thelangstonco.com"
if [[ $ENV == 'stage' ]]; then
  HOST="https://api.stage.thelangstonco.com"
elif [[ $ENV == 'dev' ]]; then
  HOST="http://localhost:3000"
elif [[ $ENV == 'prod' ]]; then
  echo "⚠️ prod is not yet supported. Try stage or dev"
  exit 1
fi


echo
echo "Requesting service account data from $HOST"

OUT_DIR="$HOME/langston-cli"
OUT_FILE="$OUT_DIR/db-service-account-$ENV.json"


http_response=$(curl --location "$HOST/db-service-account" --header 'Content-Type: application/json' --data "{\"password\": \"$PASSWORD\"}" -o $OUT_FILE -w "%{http_code}" -s)

echo

if [ "$http_response" != "200" ]; then
  echo "⚠️ Unable to get the service account file: $(jq .message <<< $(cat $OUT_FILE))"
  rm "$OUT_FILE"
else
  echo "✅  Service account file saved to $OUT_FILE"
fi

echo