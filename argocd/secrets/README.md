# Secrets

Every `SealedSecret` in the cluster, encrypted with the sealing key held by the
`sealed-secrets` controller. Safe to commit — only the controller can decrypt these.

Layout is one directory per namespace:

```
argocd/secrets/
  argocd/
    argocd-oidc.yaml
  cnpg-database/
    postgres-superuser.yaml
    postgres-admin-user.yaml
    aws-s3-credentials.yaml
  dex/
    dex-env.yaml
```

A secret referenced from `argocd-cm` as `$name:key` must also carry the label
`app.kubernetes.io/part-of: argocd`, or Argo cannot see it — set it on the plaintext
`Secret` before sealing so it survives into `spec.template.metadata`.

Synced by the [secrets Application](../infra/secrets.yaml), which recurses over this
directory — not by root, which excludes it so this can run `prune: false`. Pruning a live
`SealedSecret` would garbage-collect the `Secret` it owns. Adding a secret is a new file
here — nothing to apply by hand.

Every `SealedSecret` **must** declare `metadata.namespace`. The Application's destination
is `default`, so a manifest that omits it lands in the wrong namespace and the controller
will refuse to unseal it (the ciphertext is bound to the namespace it was sealed for).

Seal with [seal.sh](../../sealed-secrets/seal.sh) rather than calling kubeseal directly — it
strips the annotation that would otherwise commit plaintext next to the ciphertext, and
verifies the output. See [sealed-secrets/SETUP.md](../../sealed-secrets/SETUP.md).
