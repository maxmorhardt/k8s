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
2. Create directory /data/jenkins with 1000:1000 owner/group - chown -R 1000:1000 /data

## Pod Template
1. In Manage Jenkins > Clouds > kubernetes > Configure
   - Add/update jnlp, dind, and buildpack container templates with appropriate config
   - Update service account to 'jenkins'
   - Change YAML merge strategy to 'merge'
   - Change this all in jcasc config map as well

2. In Manage Jenkins > Clouds > kubernetes > Pod Templates > default
   - Lower concurrency limit to 5

JCasC should look like (both in config map and in controller):

```yaml
      clouds:
      - kubernetes:
          containerCapStr: "5"
          defaultsProviderTemplate: ""
          connectTimeout: "5"
          readTimeout: "15"
          jenkinsUrl: "http://jenkins.maxstash-global.svc.cluster.local:8080"
          jenkinsTunnel: "jenkins-agent.maxstash-global.svc.cluster.local:50000"
          skipTlsVerify: false
          usageRestricted: false
          maxRequestsPerHostStr: "32"
          retentionTimeout: "5"
          waitForPodSec: "600"
          name: "kubernetes"
          namespace: "maxstash-global"
          restrictedPssSecurityContext: false
          serverUrl: "https://kubernetes.default"
          credentialsId: ""
          podLabels:
          - key: "jenkins/jenkins-jenkins-agent"
            value: "true"
          templates:
            - name: "default"
              namespace: "maxstash-global"
              id: 2ca4c2a8a38f9f875a44b668fa5f23f249d3d06db5c18e16387b0c85d7e8bafa
              containers:
              - name: "jnlp"
                alwaysPullImage: true
                args: "^${computer.jnlpmac} ^${computer.name}"
                envVars:
                  - envVar:
                      key: "JENKINS_URL"
                      value: "http://jenkins.maxstash-global.svc.cluster.local:8080/"
                image: "jenkins/inbound-agent:3341.v0766d82b_dec0-1"
                runAsGroup: "1000"
                runAsUser: "1000"
                privileged: "false"
                ttyEnabled: false
                workingDir: /home/jenkins/agent  
              - name: "dind"
                alwaysPullImage: true
                image: "docker:dind"
                runAsGroup: "0"
                runAsUser: "0"
                resourceLimitCpu: "250m"
                resourceLimitMemory: "256Mi"
                resourceRequestCpu: "100m"
                resourceRequestMemory: "128Mi"
                privileged: "true"
                ttyEnabled: false
                workingDir: /home/jenkins/agent
              - name: "buildpack"
                alwaysPullImage: true
                image: "maxmorhardt/jenkins-buildpack:latest"
                runAsGroup: "0"
                runAsUser: "0"
                resourceLimitCpu: "1"
                resourceLimitMemory: "1Gi"
                resourceRequestCpu: "100m"
                resourceRequestMemory: "128Mi"
                privileged: "true"
                ttyEnabled: false
                workingDir: /home/jenkins/agent
              idleMinutes: 0
              instanceCap: 2147483647
              label: "jenkins-jenkins-agent "
              nodeUsageMode: "NORMAL"
              podRetention: Never
              showRawYaml: true
              serviceAccount: "jenkins"
              slaveConnectTimeoutStr: "180"
              yamlMergeStrategy: merge
              inheritYamlMergeStrategy: false
```