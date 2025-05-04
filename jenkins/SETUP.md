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
   - Update/add jnlp, dind, and buildpack container templates with appropriate config
   - Update service account to 'jenkins'
   - Update YAML merge strategy to 'merge'

JCasC should look like:

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
          image: "jenkins/inbound-agent:3307.v632ed11b_3a_c7-2"
          livenessProbe:
            failureThreshold: 0
            initialDelaySeconds: 0
            periodSeconds: 0
            successThreshold: 0
            timeoutSeconds: 0
          name: "jnlp"
          resourceLimitCpu: "200m"
          resourceLimitMemory: "256Mi"
          resourceRequestCpu: "200m"
          resourceRequestMemory: "256Mi"
          runAsGroup: "1000"
          runAsUser: "1000"
          workingDir: "/home/jenkins/agent"
        - image: "docker:28-dind"
          livenessProbe:
            failureThreshold: 0
            initialDelaySeconds: 0
            periodSeconds: 0
            successThreshold: 0
            timeoutSeconds: 0
          name: "dind"
          privileged: true
          resourceLimitCpu: "500m"
          resourceLimitMemory: "512Mi"
          resourceRequestCpu: "200m"
          resourceRequestMemory: "256Mi"
          runAsGroup: "0"
          runAsUser: "0"
          workingDir: "/home/jenkins/agent"
        - alwaysPullImage: true
          image: "maxmorhardt/jenkins-buildpack:latest"
          livenessProbe:
            failureThreshold: 0
            initialDelaySeconds: 0
            periodSeconds: 0
            successThreshold: 0
            timeoutSeconds: 0
          name: "buildpack"
          privileged: true
          resourceLimitCpu: "500m"
          resourceLimitMemory: "512Mi"
          resourceRequestCpu: "200m"
          resourceRequestMemory: "256Mi"
          runAsGroup: "0"
          runAsUser: "0"
          workingDir: "/home/jenkins/agent"
        id: "022135f78097870740d147ab5422584a59f31718160dcb9f0dd9c29da98174d2"
        label: "jenkins-jenkins-agent"
        name: "default"
        namespace: "maxstash-global"
        nodeUsageMode: "NORMAL"
        podRetention: "never"
        serviceAccount: "jenkins"
        slaveConnectTimeout: 180
        slaveConnectTimeoutStr: "180"
        yamlMergeStrategy: "merge"
```