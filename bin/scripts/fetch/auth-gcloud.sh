#!/bin/zsh

#Authorizes using Prod credentials
# Reload shell config to ensure the path is there
. "$HOME/.zshrc"

Cyan='\033[0;36m'         # Cyan
Color_Off='\033[0m'       # Text Reset
BCyan='\033[1;36m'        # Cyan

BREW_PATH=$(which brew)
if [ -x "$BREW_PATH" ] ; then
  echo "✅  gcloud utils are available!"
else
  echo
  echo "${Cyan}It looks like Google Cloud Utils are not available. "
  echo "    - ${BCyan}If you just ran `langston fetch install` and are seeing this message:${Cyan} please close this terminal window and open a new one. Then, re-run `langston fetch install`."
  echo "    - If this problem persists, please reach out to someone on the Engineering team."
  echo "${Color_Off}"
  exit 1
fi

AUTH_EMAIL=db-service-account-prod.json

if [ -f "$HOME/langston-cli/auth/$AUTH_EMAIL" ] ; then
  echo "Service account found... authenticating gcloud cli"
else
  echo "No service account file found. Do you need to authenticate the Langston CLI?"
  exit 1
fi


if gcloud auth list | grep -q "$AUTH_EMAIL"
then
  echo "Already authenticated with correct service account!"
  exit 0
else
  echo "Not currently authenticated...authenticating"
  gcloud auth login --cred-file="$HOME/langston-cli/auth/$AUTH_EMAIL" --quiet
fi

gcloud config set project langston-prod --quiet