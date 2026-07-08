# Google Auth Proxy 

A tool to securely connect to databases in the cloud

To install, choose the file that corresponds to your opereating system

## Authentication

`start.sh` resolves credentials in this order:

1. **Service-account key file** — if `~/langston-cli/auth/db-service-account-<env>.json`
   (or the legacy root location) exists, the proxy uses it. This is the managed
   path (e.g. Fetch desktop installs).
2. **Application Default Credentials (ADC)** — if no key file is present, the
   proxy authenticates as *you*, using your `gcloud` ADC. This is the preferred
   path for engineers: nothing to download, distribute, or rotate.

**Engineer setup (ADC):**

```
gcloud auth application-default login   # once, with your Langston Google account
langston db start stage                 # or: prod-replica, prod
```

Your Google identity must have `roles/cloudsql.client` on the target project
(engineers get this via the `platform-developers@thelangstonco.com` group).

If a machine has a **stale** key file, delete it to switch to ADC:
`rm ~/langston-cli/auth/db-service-account-<env>.json`.