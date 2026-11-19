#!/bin/zsh
# Google sign-in helpers shared by `langston login`, `langston db start` and
# `langston fetch`. Source this file.
#
# One Google sign-in covers everything. The Cloud SQL Auth Proxy logs in to the
# database as that account, and gcloud and Fetch read Cloud Storage as it.
# gcloud stores the sign-in as Application Default Credentials.

GOOGLE_ACCOUNT_DOMAIN='thelangstonco.com'

# The file gcloud writes on sign-in. GOOGLE_APPLICATION_CREDENTIALS overrides it.
google_credentials_file() {
  print -r -- "${GOOGLE_APPLICATION_CREDENTIALS:-${CLOUDSDK_CONFIG:-$HOME/.config/gcloud}/application_default_credentials.json}"
}

# Succeeds when this machine has a Google sign-in that still works. Google
# expires a sign-in when it wants the person to sign in again.
# The file check comes first: without the file gcloud spends several seconds
# looking for a cloud VM's credentials before it fails.
# Without gcloud on the PATH only the file is checked.
google_signed_in() {
  [[ -f "$(google_credentials_file)" ]] || return 1
  command -v gcloud >/dev/null 2>&1 || return 0
  gcloud auth application-default print-access-token >/dev/null 2>&1
}

# The account gcloud is signed in as, or nothing.
google_account() {
  gcloud config get-value account 2>/dev/null
}
