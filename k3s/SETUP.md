## Prerequisites
```bash
sudo su
ufw disable
nano /boot/firmware/cmdline.txt
add the following to the end: cgroup_enable=memory cgroup_memory=1
```

## Main Node
```bash
sudo su
curl -sfL https://get.k3s.io | INSTALL_K3S_CHANNEL=v1.33 sh -s - --tls-san "10.0.0.160" --disable traefik --kube-apiserver-arg service-node-port-range=5432-25565
echo "alias k=\"sudo k3s kubectl\"" >> .bashrc
```

For worker token:
```bash
cat /var/lib/rancher/k3s/server/token
```

For kube config:
```bash
# On local machine, replace server field with DNS or IP
cat /etc/rancher/k3s/k3s.yaml
# Eventually get kubeconfig from rancher
```

## Worker Node
```bash
sudo su
curl -sfL https://get.k3s.io | INSTALL_K3S_CHANNEL=v1.33 K3S_URL=https://10.0.0.160:6443 K3S_TOKEN=<token> sh -
```

## Port Forwarding
The following ports should be open
- 6443 (K8s)
- 80 (HTTP)
- 443 (HTTPS)

## Other
Delete k3s main node: 
```bash
/usr/local/bin/k3s-uninstall.sh
```

Delete k3s worker node: 
```bash
/usr/local/bin/k3s-agent-uninstall.sh
```

Install nginx ingress:
```bash
# Inside k8s repo
./k3s/ingress.sh
```

Upgrades:
```bash
# SCP rehydrate.sh and upgrade-<NODE_TYPE>.sh in nodes
mv rehydrate.sh /usr/local/bin
mv upgrade-<NODE_TYPE>.sh /usr/local/bin
chmod +x /usr/local/bin/rehydrate.sh /usr/local/bin/upgrade-<NODE_TYPE>.sh
# Run scripts whenever required
```