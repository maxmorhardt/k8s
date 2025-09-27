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
          containerCap: 5
          containerCapStr: "5"
          jenkinsTunnel: "jenkins-agent.maxstash-global.svc.cluster.local:50000"
          jenkinsUrl: "http://jenkins.maxstash-global.svc.cluster.local:8080"
          name: "kubernetes"
          namespace: "maxstash-global"
          podLabels:
          - key: "jenkins/jenkins-jenkins-agent"
            value: "true"
          serverUrl: "https://kubernetes.default"
          templates:
          - containers:
            - args: "^${computer.jnlpmac} ^${computer.name}"
              envVars:
              - envVar:
                  key: "JENKINS_URL"
                  value: "http://jenkins.maxstash-global.svc.cluster.local:8080/"
              image: "jenkins/inbound-agent:3327.v868139a_d00e0-7"
              name: "jnlp"
              alwaysPullImage: true
              runAsGroup: "1000"
              runAsUser: "1000"
              workingDir: "/home/jenkins/agent"
            - image: "docker:dind"
              livenessProbe:
                failureThreshold: 0
                initialDelaySeconds: 0
                periodSeconds: 0
                successThreshold: 0
                timeoutSeconds: 0
              name: "dind"
              alwaysPullImage: true
              privileged: true
              resourceLimitCpu: "250m"
              resourceLimitMemory: "256Mi"
							resourceRequestCpu: "100m"
              resourceRequestMemory: "128Mi"
              runAsGroup: "0"
              runAsUser: "0"
              workingDir: "/home/jenkins/agent"
            - image: "maxmorhardt/jenkins-buildpack:latest"
              livenessProbe:
                failureThreshold: 0
                initialDelaySeconds: 0
                periodSeconds: 0
                successThreshold: 0
                timeoutSeconds: 0
              name: "buildpack"
              alwaysPullImage: true
              privileged: true
              resourceLimitCpu: "1"
              resourceLimitMemory: "1Gi"
              resourceRequestCpu: "100m"
              resourceRequestMemory: "128Mi"
              runAsGroup: "0"
              runAsUser: "0"
              workingDir: "/home/jenkins/agent"
            id: "d05f1a832f8657e0e01902696b5ad35b806d9d41ec6657c6d16c768c8d712d47"
            label: "jenkins-jenkins-agent"
            name: "default"
            namespace: "maxstash-global"
            nodeUsageMode: NORMAL
            podRetention: "never"
            serviceAccount: "jenkins"
            slaveConnectTimeout: 180
            slaveConnectTimeoutStr: "180"
            yamlMergeStrategy: "merge"
```