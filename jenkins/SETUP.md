## Secrets Required

Create the `jenkins` secret manually before deployment:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: jenkins
  namespace: jenkins
type: Opaque
data:
  jenkins-admin-user: <base64-encoded-admin-username>
  jenkins-admin-password: <base64-encoded-admin-password>
```

## SAML

### In Authentik:
1. Create a SAML Provider for Jenkins
   - ACS URL: `https://jenkins.maxstash.io/securityRealm/finishLogin`
   - Audience/Entity ID: `https://jenkins.maxstash.io`
   - Service Provider Binding: HTTP-POST

2. Create an Application linked to the provider
   - Name: Jenkins
   - Slug: jenkins

3. Create a group for Jenkins admins (jenkins-admin)

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
          jenkinsUrl: "http://jenkins.jenkins.svc.cluster.local:8080"
          jenkinsTunnel: "jenkins-agent.jenkins.svc.cluster.local:50000"
          skipTlsVerify: false
          usageRestricted: false
          maxRequestsPerHostStr: "32"
          retentionTimeout: "5"
          waitForPodSec: "600"
          name: "kubernetes"
          namespace: "jenkins"
          restrictedPssSecurityContext: false
          serverUrl: "https://kubernetes.default"
          credentialsId: ""
          podLabels:
          - key: "jenkins/jenkins-jenkins-agent"
            value: "true"
          templates:
            - name: "default"
              namespace: "jenkins"
              id: 2ca4c2a8a38f9f875a44b668fa5f23f249d3d06db5c18e16387b0c85d7e8bafa
              containers:
              - name: "jnlp"
                alwaysPullImage: true
                args: "^${computer.jnlpmac} ^${computer.name}"
                envVars:
                  - envVar:
                      key: "JENKINS_URL"
                      value: "http://jenkins.jenkins.svc.cluster.local:8080/"
                image: "jenkins/inbound-agent:latest-jdk21"
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
                resourceLimitCpu: "500m"
                resourceLimitMemory: "512Mi"
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
                resourceLimitMemory: "2Gi"
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

## Prometheus
- Namespace should be jenkins or will get invalid metric name error