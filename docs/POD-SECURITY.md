# Pod Security Standards Guide

This guide helps you deploy parsedmarc-helm in Kubernetes clusters with strict Pod Security Standards (PSS) or Pod Security Policies (PSP).

## Understanding the Issue

OpenSearch requires `vm.max_map_count >= 262144` to run. The default chart configuration uses a privileged init container to set this automatically. However, strict security policies may block:

1. **Privileged containers** - Required by sysctlInit
2. **Root users** - Some init containers run as root
3. **Capability escalation** - Security policies may restrict this

## Quick Fix

If you're seeing pod security errors, you need to:

1. **Set vm.max_map_count on nodes manually** (see options below)
2. **Disable the privileged init container:**

```yaml
opensearch:
  sysctlInit:
    enabled: false
```

## Complete Setup for Restricted Environments

### Step 1: Set vm.max_map_count on Nodes

Choose one option:

**Option A: DaemonSet in kube-system (Recommended)**

```bash
kubectl apply -f - <<YAML
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: opensearch-sysctl
  namespace: kube-system
spec:
  selector:
    matchLabels:
      name: opensearch-sysctl
  template:
    metadata:
      labels:
        name: opensearch-sysctl
    spec:
      hostPID: true
      hostNetwork: true
      initContainers:
      - name: sysctl
        image: busybox:latest
        command: ['sh', '-c', 'sysctl -w vm.max_map_count=262144']
        securityContext:
          privileged: true
      containers:
      - name: pause
        image: registry.k8s.io/pause:3.9
        resources:
          requests:
            cpu: 5m
            memory: 8Mi
YAML
```

**Option B: Manual on each node**

```bash
# SSH to each node
sudo sysctl -w vm.max_map_count=262144
echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
```

### Step 2: Install with Restricted Configuration

```yaml
# values.yaml
parsedmarc:
  image:
    repository: ghcr.io/modalsource/parsedmarc-helm
    tag: latest
  imap:
    host: "imap.example.com"
    user: "dmarc@example.com"
    password: "your-password"

opensearch:
  # Disable privileged init container
  sysctlInit:
    enabled: false
  
  # Ensure non-root
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    allowPrivilegeEscalation: false
  
  podSecurityContext:
    runAsNonRoot: true
    runAsUser: 1000
    fsGroup: 1000
```

Install:
```bash
helm install parsedmarc charts/parsedmarc -f values.yaml
```

## Verification

```bash
# Check pods are running
kubectl get pods -n parsedmarc

# Verify vm.max_map_count
kubectl debug node/<node-name> -it --image=busybox -- sysctl vm.max_map_count

# Should show: vm.max_map_count = 262144
```

For more details, see [TROUBLESHOOTING.md](../TROUBLESHOOTING.md)
