# Google Auth Proxy 

A tool to securely connect to databases in the cloud

To install, choose the file that corresponds to your opereating system

## Authentication

`start.sh` picks a credential this way:

1. **The Google sign-in on this machine** (`langston login`). The proxy reaches
   Cloud SQL as that person. For `stage` and `prod` it also logs in to Postgres
   as them (`--auto-iam-authn`): connect as your email with no password. Fetch
   desktop does this. Password logins for built-in users (`postgres`,
   `analyst`) keep working through the same proxy.
2. Otherwise, a **service-account key file** if one is installed
   (`~/langston-cli/auth/db-service-account-<env>.json` or the legacy root
   location). This keeps Fetch releases that log in with a password working on
   machines that have not signed in yet. Nothing installs this file any more.
3. Otherwise the proxy does not start and tells you to run `langston login`.

Before step 1, `start` and `restart` renew a missing or expired sign-in
themselves (the browser opens) when a person is at a terminal, or when
`--login` is passed. Without a terminal and without `--login` they never open
a browser, because agents and scripts call them with nobody present.

`LANGSTON_AUTH_ADC=1` skips step 2.

`prod-replica` is started without `--auto-iam-authn`. It serves password
logins for the database tools, and Fetch never connects to it.

A proxy reads its credentials once, at launch. `start` records which
credential it launched with, and replaces a running proxy whose credential is
not the one it would pick now: after you sign in, switch accounts, or when the
proxy was started by an older CLI.

After launch the script polls `/readiness` and probes the tunnel (a Postgres
SSLRequest sent through the local port, no credentials needed), and only
reports success once a connection reaches Cloud SQL; a stale key or a Google
account without access fails loudly (with a log tail) instead of a false "started".

## When the proxy hangs

A proxy can report `/readiness` 200 while every connection hangs or fails with
`tls: bad certificate` — typically after the laptop sleeps through a
certificate refresh. `--lazy-refresh` (v2.26.0, installed automatically by
`start`) removes the usual cause. When it still happens:

- `langston db check <env>` probes the tunnel and exits non-zero when it is broken.
- `langston db restart <env>` stops (SIGKILL if the proxy does not answer) and
  starts it. `start`, `stop` and `restart` of one target serialize on a
  kernel lock (released when its holder exits), and a restart that waited
  re-checks before restarting again — so agents can call it freely.
- `start` on a running-but-broken proxy replaces it.

The previous run's log is kept at `$TMPDIR/langston-auth-proxy-<env>.log.1`.

## Setup

```
langston login            # once; opens the browser
langston db start stage
```

Your Google account needs `roles/cloudsql.client` on the target project.
Engineers get it through the `platform-developers@thelangstonco.com` group and
Fetch users through `fetch-users@thelangstonco.com`. Logging in to Postgres as
yourself also needs the `fetch-users@` group; see "Fetch Desktop Access" in the
`langston-infra` README.
