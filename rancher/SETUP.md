## OIDC
Once Rancher and Keycloak are setup, do the following

### In Keycloak:
1. Create Client in Keycloak realm for Rancher
	- Client Authentication must be true to obtain client secret
	- Redirect urls and post logout urls should include https://<dns> and https://<dns>/*
	- Standard flow and Direct Access Grants should be true
	- Configure rancher-dedicated scope (https://ranchermanager.docs.rancher.com/how-to-guides/new-user-guides/authentication-permissions-and-global-configuration/authentication-config/configure-keycloak-oidc)

2. Create group for Rancher Admin

3. Create service account for Rancher
	- Add the account to the group
	- Ensure the account has view/query users and groups permissions

4. Log into service account

### In Rancher:
1. Under Users & Authentication, select Keycloak OIDC Auth Provider and fill in required fields
	- As of 3/8/25, Rancher's auto generated keycloak url is wrong. Remove /auth from the beginning of the path

2. Once setup, select restrict to users and groups and select Rancher Admin group

3. Setup Rancher Admin
	- Under Users & Authentication, select Groups
	- Search for your group and select Administrator