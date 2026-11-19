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

# Whether a `langston db` command may open the browser to sign in. It may when
# a person is at a terminal, or when the caller passed --login (Fetch does,
# because its window has no terminal). Agents and scripts call these commands
# with nobody present, so the default without a terminal is no.
google_sign_in_allowed() {
  [[ "$LANGSTON_LOGIN" == "1" ]] || [[ -t 0 && -t 1 ]]
}

# The folder this file is in, to find auth.sh from whichever script sources it.
GOOGLE_AUTH_DIR=${${(%):-%x}:A:h}

# Renews a missing or expired Google sign-in when that is allowed. Call it
# before taking a target's lock and before changing a proxy: the browser step
# can take as long as the person does, or never finish.
# Returns 1 only when a sign-in was attempted and the credentials this command
# uses still do not work, for example when GOOGLE_APPLICATION_CREDENTIALS
# points at a file the sign-in does not write.
renew_google_sign_in() {
  google_signed_in && return 0
  google_sign_in_allowed || return 0
  echo "Your Google sign-in is missing or has expired. Signing in again..."
  "$GOOGLE_AUTH_DIR/auth.sh" || return 1
  google_signed_in && return 0
  echo "🛑  Signed in, but the credentials this command uses still do not work: $(google_credentials_file)"
  return 1
}

# Reads the arguments of `langston db start|restart`: an optional target and
# an optional --login, in either order. Sets DB_TARGET and LANGSTON_LOGIN.
parse_db_arguments() {
  DB_TARGET=''
  local argument
  for argument in "$@"; do
    if [[ "$argument" == '--login' ]]; then
      export LANGSTON_LOGIN=1
    elif [[ -z "$DB_TARGET" ]]; then
      DB_TARGET="$argument"
    fi
  done
}

# The account gcloud commands run as (`gcloud storage`), or nothing.
google_account() {
  gcloud config get-value account 2>/dev/null
}

# The account behind the sign-in the proxy and Fetch use, or nothing. gcloud
# keeps this separately from google_account, and the two can differ: ask
# Google who the credentials belong to rather than trusting either file.
# The token goes to curl on stdin so it never appears in a process list.
google_credentials_account() {
  local token
  token=$(gcloud auth application-default print-access-token 2>/dev/null) || return 1
  print -r -- "header = \"Authorization: Bearer $token\"" \
    | curl --silent --max-time 10 --config - 'https://openidconnect.googleapis.com/v1/userinfo' \
    | jq -r '.email // empty' 2>/dev/null
}

# Identifies the contents of a credential file without revealing them, so
# start.sh can tell when a running proxy holds a different sign-in.
credential_fingerprint() {
  shasum -a 256 < "$1" | cut -d ' ' -f 1
}
