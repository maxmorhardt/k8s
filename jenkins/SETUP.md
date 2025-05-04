## OIDC

### In Keycloak:
1. Create Client in Keycloak realm for Jenkins
   - Client Authentication must be true to obtain client secret
   - Redirect urls and post logout urls should include https://<dns> and https://<dns>/*
   - Standard flow and Direct Access Grants should be true
   - Configure jenkins-dedicated scope with Group Membership for claim name 'groups'

2. Create group for Jenkins Admin

## Storage
1. SSH into node that will host Jenkins
2. Create directory /data/jenkins with 1000:1000 owner/group 

## Pod Template
1. In Manage Jenkins > Clouds > kubernetes > Pod Templates > default
   - Change jnlp container cpu and memory request/limit to 256
   - Change service account to jenkins