# AGENTS

## Project Context

- Project: Self-Hosted Kubernetes Stack (`github.com/maxmorhardt/k8s`)
- Language: YAML (Helm values, Kubernetes manifests, Argo CD Applications), plus HCL for out-of-cluster resources and shell for bootstrap
- Purpose: The GitOps source of truth for a self-hosted K3s cluster. Argo CD reconciles everything here into the cluster.
- Target environments: A single on-premises K3s cluster with Tailscale on nodes, high availability at the application level.
- Related repos: `charts` (chart source for the apps deployed here), `workflows` (the shared validation workflows this repo's CI calls).

**Editing a file and merging to `main` is the deploy.** There is no `helm upgrade` step, no per-component `deploy.sh`, and no CI workflow anywhere that holds a kubeconfig. `terraform/` deploys the same way, by `terraform apply` in CI rather than an Argo sync.

## Repository Layout

- `argocd/` - the control plane for everything else.
  - `root.yaml` - the app-of-apps pointing Argo at `infra/` and `apps/`.
  - `infra/*.yaml` - one `Application` per infrastructure component, pointing at that component's directory here or at an upstream chart.
  - `apps/*.yaml` - one `Application` per deployed application. Source is `ghcr.io/maxmorhardt/charts` with a pinned `targetRevision` and an `image.tag` Helm parameter.
  - `secrets/<namespace>/` - SealedSecrets, encrypted at rest and safe to commit.
  - `bootstrap.sh` - installs and repairs Argo CD itself. Run by hand from a workstation with cluster access.
  - `SETUP.md` - how Argo CD is configured and bootstrapped.
- `<component>/` - one directory per infra component (`alloy/`, `dex/`, `envoy-gateway/`, `kured/`, `loki/`, `nats/`, `postgres/`, `prometheus-stack/`, `sealed-secrets/`, `storage/`, `system-upgrade-controller/`, `k3s/`), each with its `values.yaml` or raw manifests plus a `SETUP.md`.
- `prometheus-stack/dashboards/` - Grafana dashboard JSON plus a `kustomization.yaml` wrapping each file into a ConfigMap. Deployed by its own `grafana-dashboards` Application.
- `cloudflare-maintenance/` - Cloudflare Worker serving a maintenance page. Deployed with wrangler, not Kubernetes.
- `terraform/` - the resources Argo CD cannot reach: the S3 backup bucket with its IAM identity, Cloudflare DNS, and GitHub repository rulesets. Three root modules (`aws/`, `cloudflare/`, `github/`), remote state in S3, planned on PR and applied on merge by `cd-terraform.yml`. See `terraform/SETUP.md`.
- `namespaces.sh` - creates namespaces on a bare cluster, before Argo CD exists.
- `.github/workflows/ci-k8s.yml` - chart, manifest, and Terraform validation via the shared workflows, fanning into the `Validate Complete` check the rulesets require. **Never applies to the cluster.**
- `.github/workflows/cd-terraform.yml` - applies `terraform/` on merge, and plans it weekly with `fail_on_diff` to catch drift.

## Core Principles

1. Every change is a deploy
   - Treat a merge to `main` as a production rollout.
   - Argo runs with `prune: true` and `selfHeal: true`, so deleting a resource from git deletes it from the cluster, and a manual `kubectl edit` is reverted on the next sync.
2. Git is the only source of truth
   - Nothing reaches the cluster except through a commit here. Every version running is a commit you can read, review, and revert.
3. CI never touches the cluster
   - No workflow holds a kubeconfig or cluster credentials. Argo pulls; CI does not push.
   - Argo CD itself is the one exception, bootstrapped by hand because it cannot deploy itself from nothing.
4. Secrets are encrypted, never plaintext
   - Only SealedSecrets are committed. The sealing key is restored out of band.
5. Separation of concerns with `charts`
   - `charts` holds chart source. This repo holds which version of that chart runs, and where.
6. Ownership of pinned lines
   - `image.tag` and `targetRevision` in `argocd/apps/` are written by CI in the app and `charts` repos. Editing them by hand works but is overwritten by the next release.
7. Runbooks live beside config
   - Each component's `SETUP.md` is its operational runbook and stays current with its values file.
8. Terraform is applied, not reconciled
   - A merge applies `terraform/`, but nothing watches it afterwards. Drift stays invisible until the Monday scheduled plan, unlike Argo's continuous self-heal.
   - Everything it manages already existed and was adopted by import. A plan reporting anything other than no changes means the HCL is wrong, not the infrastructure.

## Agent Instructions

- Make the smallest safe change that solves the requested problem.
- Change infra behavior by editing the component's `values.yaml`, not the `Application`. Change which chart version runs by editing `targetRevision` in the `Application`.
- **Never commit a plaintext `Secret`.** Seal it first (see `sealed-secrets/SETUP.md`) and put the SealedSecret in `argocd/secrets/<namespace>/`. Files named `*.example.yaml` are committed templates with placeholder values.
- Adding a component means creating `<component>/` with `values.yaml` and `SETUP.md`, then adding `argocd/infra/<component>.yaml`. Nothing runs until the `Application` exists.
- Grafana runs on SQLite and dashboards are provisioned from ConfigMaps, so a dashboard edited in the Grafana UI is not persisted. Export the JSON and commit it to `prometheus-stack/dashboards/`.
- When a values change alters how a component is reached, backed up, or recovered, update its `SETUP.md` in the same commit.
- In `terraform/`, never resolve a plan diff by changing live infrastructure. Match the HCL to what exists, then change it deliberately in its own commit. `aws_s3_bucket.backups` carries `prevent_destroy` because it holds the database backups.
- Deleting a file is a destructive cluster operation. Confirm the resource is genuinely meant to be removed, not just moved.

## New Component Checklist

1. Create `<component>/` with `values.yaml` (or raw manifests).
2. Write `<component>/SETUP.md` covering how it is reached, configured, backed up, and recovered.
3. Add `argocd/infra/<component>.yaml` with the destination namespace and sync policy.
4. Add any namespace it needs to `namespaces.sh`.
5. Seal and commit its secrets under `argocd/secrets/<namespace>/`.
6. Render and validate locally before pushing.

## Testing Guidance

Rendering and validating is the test. There is no test suite; a bad merge reconciles straight into the cluster.

```bash
helm template <name> <chart> -f <component>/values.yaml   # infra values
kubeconform -strict -summary <manifest>                   # raw manifests
kustomize build prometheus-stack/dashboards               # dashboards
terraform -chdir=terraform/<module> validate              # HCL
terraform -chdir=terraform/<module> plan                  # against live state
```

- Always render before pushing. A values key that the upstream chart does not recognize is silently ignored, so confirm the rendered output actually changed the way you expect.
- For an `Application` change, verify the chart version exists at the referenced `repoURL` first. Argo will sit in a failed sync otherwise.
- For alert or dashboard changes, validate the JSON or rule renders before committing, since Grafana and Prometheus fail quietly on malformed input.
- After merging, watch the Argo sync rather than assuming success. `prune` means a mistake can remove resources, not just fail to add them.

## Dependency Checklist

Before adding a new component or upstream chart, verify:

- Does an existing component already cover this? The stack deliberately runs one thing per concern.
- What are its CRD requirements, and what breaks if it syncs before those CRDs exist?
- What is its resource footprint? This is a small on-premises cluster, not a cloud autoscaling group.
- Does it need persistent storage, and does the `local-path-retain` StorageClass with a Retain policy suit it?
- Does it need secrets, and are those sealable?
- Is it covered by monitoring and alerting once it is running?

## Architecture

- **Ingress**: a single Envoy Gateway (Gateway API) for all traffic. UIs get a hostname each; APIs share `api.maxstash.io` split by path prefix. TLS terminates at the gateway. Charts attach via `HTTPRoute` with a `parentRef` to the `maxstash` gateway in `envoy-gateway-system`.
- **Auth**: Dex at `login.maxstash.io` provides OIDC, federating Google and GitHub. Email is the identity.
- **Data**: PostgreSQL HA via CloudNativePG (`postgres-operator` plus `postgres-cluster`), NATS for pub/sub.
- **Observability**: kube-prometheus-stack (Prometheus, Alertmanager, Grafana) plus Loki and Alloy for logs. Alertmanager routes to Discord and email with a healthchecks.io dead-man's switch.
- **Node maintenance**: kured coordinates rolling reboots Tuesdays at 02:00, one node at a time, running `pre-reboot.sh` first. system-upgrade-controller tracks the k3s stable channel in a Wednesday 02:00 to 04:00 ET window, control plane first.

## Bootstrap Order

On a bare cluster only. Everything after step 3 is reconciled automatically.

1. K3s cluster with Tailscale on nodes
2. `./namespaces.sh`
3. `cd argocd && ./bootstrap.sh`
4. Restore the Sealed Secrets private key **before** anything needing a secret syncs
5. Storage, Postgres, Envoy Gateway, kube-prometheus-stack, NATS, Loki, Alloy, Dex, kured, system-upgrade-controller

Apps installed before the Prometheus CRDs exist will fail to sync. Argo retries until they do.

## Commit Tags

Conventional commits, enforced on PR titles by `pr-title.yml`. There is no release-please here, so the commit itself is the release.

- `feat`: New component, or new capability on an existing one.
- `fix`: Corrects broken or unsafe cluster configuration.
- `chore`: Maintenance that does not change cluster behavior, including routine version bumps.
- `ci`: Validation workflow changes.
- `docs`: `README.md` or a `SETUP.md` only.

Scope is the component or app directory.

Example commit subjects:

- `feat(dex): add github connector`
- `fix(loki): raise retention to 30d`
- `chore(argocd): bump squares targetRevision to 1.0.3`
- `chore(terraform): import the bucket policy`
- `docs(postgres): document the recovery values file`

## Non-Goals for Routine Changes

- Applying anything to the cluster from CI, or adding a kubeconfig to a workflow.
- Committing a plaintext Secret.
- Hand-editing `image.tag` or `targetRevision`, which CI owns.
- Adding a component directory without its Argo CD `Application`.
- Working around Argo by running `kubectl edit`, which `selfHeal` reverts anyway.
- Adding a second component that duplicates a concern the stack already covers.
- Managing cluster resources with Terraform, or out-of-cluster resources with Argo CD.
