## Overview

A single Cloudflare Worker that serves one maintenance page for the **entire**
`maxstash.io` zone. It runs on Cloudflare's edge, *before* traffic is proxied to
your home IP, so it works even when the whole k3s cluster (and origin) is down.

Deployed **only during a planned outage**. The rest of the time the Worker does
not exist and traffic reaches the cluster normally.

- `worker.js` — the page (HTML for UIs, JSON `503` for `api.*`). Returns HTTP
  `503` + `Retry-After` so crawlers treat the outage as temporary.
- `wrangler.toml` — Worker name + zone routes (`maxstash.io/*`, `*.maxstash.io/*`).

Nothing here is reconciled by Argo CD — Cloudflare Workers live at the edge, not
in the cluster, which is the whole point.

## Prerequisites

- Node.js installed, then Wrangler (Cloudflare's CLI):
  ```bash
  npm install -g wrangler
  wrangler login        # OAuth in the browser, one time
  ```

## Enable maintenance (before taking the cluster down)

From this directory:

```bash
wrangler deploy
```

That publishes the Worker and attaches both zone routes. Every hostname on
`maxstash.io` — apps, `api.`, `login.`, `grafana.`, the apex — immediately serves
the maintenance page. No DNS changes, existing Cloudflare TLS is used, effect is
near-instant.

Verify:

```bash
curl -sI https://maxstash.io | grep -i '^http\|retry-after'
curl -s  https://api.maxstash.io/anything    # -> JSON 503
```

## Disable maintenance (when the cluster is back)

```bash
wrangler delete
```

Deleting the Worker removes its routes, so traffic flows to Envoy Gateway again.
Confirm an app loads before walking away.

## Notes

- **Ordering vs. `cloudflare-ddns`:** the DDNS cronjob runs in-cluster, so it is
  not running while the cluster is down and never fights this. DNS records are
  untouched by this Worker either way — only the Worker route changes.
- **Editing the message:** change the `HTML` string (or the API JSON) in
  `worker.js` and re-run `wrangler deploy`.
- **Toggle without deleting:** you can also enable/disable the route from the
  Cloudflare dashboard (Workers & Pages → maxstash-maintenance → Triggers) if you
  prefer to keep the Worker published but inactive.
- **Multiple Cloudflare accounts:** set `account_id` in `wrangler.toml`.
