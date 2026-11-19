#!/bin/zsh
# `langston login` (alias: `langston auth`). Signs this machine in to Google.
#
# Opens the browser only when there is no working sign-in, so Fetch can run it
# on every launch. Pass --force to sign in again, for example to switch accounts.
#
# The sign-in replaces the service account key this command used to download:
# database and Cloud Storage access now belong to the person's own account.

SCRIPT_DIR=${0:A:h}
source "$SCRIPT_DIR/google-auth.sh"

if ! command -v gcloud >/dev/null 2>&1; then
  "$SCRIPT_DIR/../fetch/install-gcloud.sh" || exit 1
  # install-gcloud.sh adds gcloud to the PATH through .zshrc.
  . "$HOME/.zshrc"
fi

is_work_account() {
  [[ "$1" == *"@$GOOGLE_ACCOUNT_DOMAIN" ]]
}

# gcloud keeps two sign-ins: one for its own commands (the Fetch download) and
# one for the proxy and Fetch. Both must be the same work account.
signed_in_as_one_work_account() {
  google_signed_in || return 1
  local account
  account=$(google_credentials_account)
  is_work_account "$account" && [[ "$account" == "$(google_account)" ]]
}

if [[ "$1" != '--force' ]] && signed_in_as_one_work_account; then
  echo "✅  Signed in to Google as $(google_account)"
  exit 0
fi

echo
echo "🔑  Opening your browser to sign in to Google."
echo "    Choose your @$GOOGLE_ACCOUNT_DOMAIN account, then click Allow."
echo

if ! gcloud auth login --update-adc; then
  echo
  echo "🛑  The Google sign-in did not finish. Run \"langston login\" to try again."
  exit 1
fi

# `gcloud auth login --update-adc` sets both sign-ins to the chosen account.
ACCOUNT=$(google_credentials_account)
if ! is_work_account "$ACCOUNT"; then
  echo
  echo "🛑  You signed in as \"$ACCOUNT\", which is not a @$GOOGLE_ACCOUNT_DOMAIN account."
  echo "    Run \"langston login --force\" and choose your work account."
  exit 1
fi

echo
echo "✅  Signed in to Google as $ACCOUNT"
