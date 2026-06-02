# Branding

Set under **System > Brands > Edit brand**.

- **Custom CSS** — paste [`branding/custom.css`](../branding/custom.css). Covers login-card cleanup, logo sizing, hiding the locale selector / "Powered by authentik" / page-credentials tab, dark-theme autofill fixes, and disabling the filter that inverts [social login icons](social-providers.md).
- **Attributes**:
  ```yaml
  settings:
    theme:
      base: dark
  ```
