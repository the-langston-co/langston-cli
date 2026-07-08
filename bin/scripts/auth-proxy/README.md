# Google Auth Proxy 

A tool to securely connect to databases in the cloud

To install, choose the file that corresponds to your opereating system

## Authentication

`start.sh` picks a credential this way:

1. **`LANGSTON_AUTH_ADC=1`** → Application Default Credentials, ignoring any key
   file. Use this to switch to ADC without hunting down a stale key, and to use
   ADC for `prod`/`prod-replica`.
2. Otherwise, a **service-account key file** if present
   (`~/langston-cli/auth/db-service-account-<env>.json` or the legacy root
   location) — the managed path (e.g. Fetch desktop installs), stable non-human
   identity.
3. Otherwise, for **stage only**, ADC. For `prod`/`prod-replica` with no key,
   the proxy refuses to start (so it never silently connects as a human
   identity) — install the managed key or set `LANGSTON_AUTH_ADC=1`.

After launch the script polls the proxy's `/readiness` endpoint and only reports
success once the tunnel is actually usable; a stale key or unauthorized ADC
fails loudly (with a log tail) instead of a false "started".

**Engineer setup (ADC):**

```
gcloud auth application-default login   # once, with your Langston Google account
langston db start stage
```

Your Google identity needs `roles/cloudsql.client` on the target project
(engineers get this via the `platform-developers@thelangstonco.com` group).

Have a **stale** key file? Either delete it
(`rm ~/langston-cli/auth/db-service-account-<env>.json`) or run with
`LANGSTON_AUTH_ADC=1 langston db start <env>`.