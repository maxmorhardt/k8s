## OIDC

### In Keycloak:
1. Create Client in Keycloak realm for Grafana
   - Client Authentication must be true to obtain client secret
   - Redirect urls and post logout urls should include https://<dns> and https://<dns>/*
   - Standard flow and Direct Access Grants should be true
   - Configure grafana-dedicated scope with Group Membership for claim name 'groups'
   - More details: https://grafana.com/docs/grafana/latest/setup-grafana/configure-security/configure-authentication/keycloak/

2. Create group for Grafana Admin