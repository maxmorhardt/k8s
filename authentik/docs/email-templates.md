# Email Templates

Branded overrides for authentik's stock emails. Templates live in [`templates/`](../templates/) and mount into the pods at `/templates`.

| File | Purpose |
|------|---------|
| [`templates/password_recovery.html`](../templates/password_recovery.html) | Password reset email for the recovery flow |

## How they work

- Django HTML templates extending `{% extends "email/base.html" %}`.
- Email-stage context: `url` (action link), `user` (`user.username`, …), `expires` (`{{ expires|naturaltime }}`).
- Sent by the **worker**, read for the dropdown by the **server** — must be mounted on both (the `global.volumeMounts` in `values.yaml` covers both).

## Deploy

1. ConfigMap from the templates:
   ```bash
   kubectl create configmap authentik-email-templates \
     --from-file=password_recovery.html=templates/password_recovery.html \
     -n authentik --dry-run=client -o yaml | kubectl apply -f -
   ```
2. Mount at `/templates` — append to `global.volumes` / `global.volumeMounts` in [`values.yaml`](../values.yaml):
   ```yaml
   global:
     volumes:
       - name: email-templates
         configMap:
           name: authentik-email-templates
     volumeMounts:
       - name: email-templates
         mountPath: /templates
   ```
3. `./deploy.sh` to roll the pods.

## Use it

**Flows & Stages → Stages** → edit the recovery flow's **Email** stage → **Template** → `password_recovery.html`. Trigger a reset to test; if it's missing from the dropdown, check **worker logs** for a template error. Re-apply the ConfigMap and roll pods after edits.
