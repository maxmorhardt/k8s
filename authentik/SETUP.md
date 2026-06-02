# authentik Setup

Self-hosted authentik for `login.maxstash.io`, deployed via Helm to Kubernetes.

## Guides

| Doc | Covers |
|-----|--------|
| [docs/deployment.md](docs/deployment.md) | Secrets, PostgreSQL, deploy steps |
| [docs/initial-config.md](docs/initial-config.md) | Post-deploy in-UI config: settings, password policy, flows, users/groups, brand |
| [docs/branding.md](docs/branding.md) | Custom CSS and brand attributes |
| [docs/social-providers.md](docs/social-providers.md) | Google / GitHub / Discord social login |
| [docs/email-templates.md](docs/email-templates.md) | Custom branded emails (password recovery) |
| [docs/outpost.md](docs/outpost.md) | Embedded outpost / proxy forward auth |

## Layout

```
.
├── deploy.sh                     # helm upgrade --install
├── values.yaml                   # helm values
├── secret.example.yaml           # template for the authentik secret
├── branding/
│   └── custom.css                # brand Custom CSS
├── templates/
│   └── password_recovery.html    # custom recovery email
└── docs/                         # the guides above
```

Start with [docs/deployment.md](docs/deployment.md).
