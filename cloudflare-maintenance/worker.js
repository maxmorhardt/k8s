// Edge maintenance page for the whole maxstash.io zone.
// Runs on Cloudflare's network, so it serves regardless of the cluster/origin
// state. Deployed only while the cluster is intentionally down (see SETUP.md).
// API hosts get JSON so fetch clients degrade gracefully; everything else gets HTML.

const RETRY_AFTER = "86400"; // seconds (24h) — hint for crawlers/clients, planned outage

const HTML = `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
<meta name="robots" content="noindex" />
<title>Down for maintenance</title>
<style>
  :root { color-scheme: dark; }
  * { box-sizing: border-box; }
  html, body { height: 100%; margin: 0; }
  body {
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
    color: #e0e7ff;
    background: linear-gradient(135deg, #121212 0%, #1e1e1e 100%);
    display: flex; align-items: center; justify-content: center;
    padding: 24px; text-align: center;
  }
  .card { max-width: 32rem; }
  .badge {
    width: 72px; height: 72px; margin: 0 auto 28px;
    border-radius: 20px;
    display: flex; align-items: center; justify-content: center;
    background: linear-gradient(135deg, #1976d2 0%, #1565c0 50%, #0d47a1 100%);
    box-shadow: 0 12px 40px rgba(31, 120, 180, 0.35);
  }
  .badge svg { width: 38px; height: 38px; }
  h1 {
    font-size: clamp(1.6rem, 4vw, 2.25rem);
    margin: 0 0 12px;
    background: linear-gradient(135deg, #ffffff 0%, #e0e7ff 100%);
    -webkit-background-clip: text; background-clip: text;
    -webkit-text-fill-color: transparent;
  }
  p { font-size: 1.05rem; line-height: 1.6; color: #a9b2d0; margin: 0 auto 8px; max-width: 26rem; }
  .foot { margin-top: 28px; font-size: 0.85rem; color: #6b7391; }
</style>
</head>
<body>
  <main class="card">
    <div class="badge" aria-hidden="true">
      <svg viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="1.8"
           stroke-linecap="round" stroke-linejoin="round">
        <path d="M14.7 6.3a1 1 0 0 0 0 1.4l1.6 1.6a1 1 0 0 0 1.4 0l3.77-3.77a6 6 0 0 1-7.94 7.94l-6.91 6.91a2.12 2.12 0 0 1-3-3l6.91-6.91a6 6 0 0 1 7.94-7.94l-3.76 3.76z"/>
      </svg>
    </div>
    <h1>Down for maintenance</h1>
    <p>We're performing scheduled maintenance on our infrastructure. The service will be back shortly.</p>
    <p>Thanks for your patience.</p>
    <div class="foot">maxstash.io</div>
  </main>
</body>
</html>`;

export default {
  fetch(request) {
    const url = new URL(request.url);

    // APIs: JSON, not HTML, so frontends/clients don't try to parse a webpage.
    if (url.hostname === "api.maxstash.io" || url.hostname.startsWith("api.")) {
      return new Response(
        JSON.stringify({
          error: "maintenance",
          message: "Service temporarily unavailable for scheduled maintenance.",
        }),
        {
          status: 503,
          headers: {
            "content-type": "application/json; charset=utf-8",
            "retry-after": RETRY_AFTER,
            "cache-control": "no-store",
          },
        },
      );
    }

    return new Response(HTML, {
      status: 503,
      headers: {
        "content-type": "text/html; charset=utf-8",
        "retry-after": RETRY_AFTER,
        "cache-control": "no-store",
      },
    });
  },
};
