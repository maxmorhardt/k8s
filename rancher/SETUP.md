## OIDC
Once Rancher and Authentik are setup, do the following

### In Authentik:
1. Create an OAuth2/OIDC Provider for Rancher
	- Redirect URIs: `https://rancher.maxstash.io/verify-auth`

2. Create an Application linked to the provider
	- Name: Rancher
	- Slug: rancher
	- Copy the Client ID and Client Secret

3. Create a group for Rancher admins (rancher-admin)

### In Rancher:
1. Under Users & Authentication, select Generic OIDC Auth Provider and fill in required fields
	- Auth Endpoint: `https://login.maxstash.io/application/o/authorize/`
	- Token Endpoint: `https://login.maxstash.io/application/o/token/`
	- User Info Endpoint: `https://login.maxstash.io/application/o/userinfo/`
	- Groups Field: `groups`

2. Once setup, select restrict to users and groups and select rancher-admin group

3. Setup Rancher Admin
	- Under Users & Authentication, select Groups
	- Search for your group and select Administrator