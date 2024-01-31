#!/bin/zsh

#Authorizes using Prod credentials

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