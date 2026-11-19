#!/bin/zsh
# Makes sure gcloud can download Fetch: signed in to Google as the person, with
# the production project selected.

# Reload shell config to ensure gcloud is on the PATH
. "$HOME/.zshrc"

SCRIPT_DIR=${0:A:h}

if ! command -v gcloud >/dev/null 2>&1; then
  echo
  echo "Google Cloud tools are not available yet."
  echo "    - If you just ran \"langston fetch install\": close this terminal window, open a new one, and run \"langston fetch install\" again."
  echo "    - If this keeps happening, reach out to someone on the Engineering team."
  echo
  exit 1
fi

"$SCRIPT_DIR/../configure/auth.sh" || exit 1

gcloud config set project langston-prod --quiet
