# Initial Configuration

Post-deploy config in the admin UI. Requires [deployment.md](deployment.md) done.

## System settings (System > Settings)

- **Default session duration**: `12 hours` (also set it in the login stages).
- **Event retention**: `90 days`.

## Password policy (Policies > Password Policies)

Edit the default: **Static Rules** only, **Minimum length** `8`.

## Flows

- **Recovery flow** (password reset) — branded email in [email-templates.md](email-templates.md).
- **Enrollment flow** with Cloudflare Turnstile. Stage order: `captcha → prompt → user write → user login`.

## Users & groups

Create a non-`akadmin` user and the admin groups used by apps.

## Brand

Configure the brand for `login.maxstash.io` as the new default — see [branding.md](branding.md).

## User details flow (read-only)

Read-only "user settings" flow showing email/name/username.

1. **Flows & Stages > Prompts** — create three prompts, all with **Interpret initial value as expression: ON**:
   - `email` — type `Text`, initial value `return user.email`, order `0`
   - `name` — type `Text (read-only)`, initial value `return user.name`, order `1`
   - `username` — type `Text (read-only)`, initial value `return user.username`, order `2`
2. **Stages > Create > Prompt Stage** `user-details` with all three prompts.
3. **Flows > Create** — slug `user-details`, designation `Stage Configuration`, authentication `Require authentication`.
4. **Stage Bindings** — bind `user-details` at order `0`. No User Write stage.
5. **System > Brands > Edit brand > Default flows** — set **User settings flow** to `user-details`.
