# Social Providers

Sign in with an external IdP, linked to an existing account by email. Enabled: Google, GitHub, Discord.

## 1. Provider credentials

In the provider's console, create OAuth 2.0 credentials with redirect URI `https://login.maxstash.io/source/oauth/callback/<source-slug>/`. Note the Client ID + Secret.

## 2. Create the source

**Directory → Federation & Social login → Create → OAuth Source**

- **Name** / **Slug**: e.g. `google`
- **Consumer key** / **Consumer secret**: the Client ID / Secret
- **Provider type**: the provider
- **User matching mode**: `Link to a user with identical email address`
- **Authentication flow**: `default-source-authentication`
- **Enrollment flow**: `default-source-enrollment`
- **Icon** (optional, full URL — GitHub needs white since the inversion filter is off):

  | Source | Icon URL |
  |--------|----------|
  | Discord | `https://cdn.jsdelivr.net/gh/gilbarbara/logos/logos/discord-icon.svg` |
  | Google | `https://cdn.jsdelivr.net/gh/gilbarbara/logos/logos/google-icon.svg` |
  | GitHub | `https://cdn.simpleicons.org/github/white` |

> Use the `default-source-*` flows, **not** the main `default-authentication-flow` / custom `enrollment` flow — the latter (Turnstile, password prompts) can't complete in a source context and cause a redirect loop.

## 3. Show on the login page

**Flows & Stages → Stages** → edit the **Identification** stage of `default-authentication-flow` → **Source settings** → add the source.

## 4. Source enrollment flow

**Flows & Stages → Flows** → edit `default-source-enrollment`:

- Set **Title** to something friendly (e.g. `Sign in`).
- In its **User Write** stage (`default-source-enrollment-write`), set **Create users as** `Internal` (not `External` — external users can't fully log in).
