# Troubleshooting Guide

## OpenSearch Issues

### Error: "max virtual memory areas vm.max_map_count [65530] is too low"

**Full Error:**
```
[1]: max virtual memory areas vm.max_map_count [65530] is too low, increase to at least [262144]
```

**Cause:**
OpenSearch/Elasticsearch requires the kernel parameter `vm.max_map_count` to be set to at least 262144.

**Solutions:**

#### Option 1: Enable sysctlInit (Default - Recommended)

The Helm chart includes an init container that automatically sets this value:

```yaml
opensearch:
  sysctlInit:
    enabled: true  # This is the default
```

**Requirements:**
- The init container runs as privileged
- Your Kubernetes cluster must allow privileged containers

**Limitations:**
- Some managed Kubernetes services (GKE Autopilot, EKS Fargate) don't allow privileged containers
- Pod Security Policies/Standards may block this

#### Option 2: Set on Kubernetes Nodes (Permanent Fix)

Set `vm.max_map_count` directly on each Kubernetes node:

```bash
# On each node, run:
sudo sysctl -w vm.max_map_count=262144

# To make it permanent:
echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

Then disable the init container:

```yaml
opensearch:
  sysctlInit:
    enabled: false
```

#### Option 3: Use DaemonSet (Automated Node Configuration)

Create a DaemonSet to configure all nodes:

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: sysctl-vm-max-map-count
  namespace: kube-system
spec:
  selector:
    matchLabels:
      name: sysctl-vm-max-map-count
  template:
    metadata:
      labels:
        name: sysctl-vm-max-map-count
    spec:
      hostPID: true
      hostNetwork: true
      initContainers:
      - name: sysctl
        image: busybox:latest
        command:
        - sh
        - -c
        - sysctl -w vm.max_map_count=262144
        securityContext:
          privileged: true
      containers:
      - name: pause
        image: gcr.io/google_containers/pause:latest
```

Apply with:
```bash
kubectl apply -f sysctl-daemonset.yaml
```

Then disable the init container in values:

```yaml
opensearch:
  sysctlInit:
    enabled: false
```

#### Option 4: Managed Kubernetes Specific Solutions

**GKE (Google Kubernetes Engine):**
```bash
# GKE Standard: Use node pool taints/tolerations and set via startup script
gcloud container node-pools create opensearch-pool \
  --cluster=your-cluster \
  --num-nodes=3 \
  --metadata startup-script='#!/bin/bash
sysctl -w vm.max_map_count=262144'
```

**EKS (Amazon Elastic Kubernetes Service):**
```bash
# Add to EC2 user data or use SSM to run on nodes
aws ssm send-command \
  --document-name "AWS-RunShellScript" \
  --parameters 'commands=["sysctl -w vm.max_map_count=262144"]' \
  --targets "Key=tag:kubernetes.io/cluster/your-cluster,Values=owned"
```

**AKS (Azure Kubernetes Service):**
```bash
# Create custom node pool with VM settings
az aks nodepool add \
  --cluster-name your-cluster \
  --name opensearch \
  --node-count 3 \
  --node-vm-size Standard_D4s_v3
```

Then SSH to nodes and set sysctl.

### Verification

After applying any solution, verify the setting:

```bash
# On the Kubernetes node:
sysctl vm.max_map_count

# Should output:
vm.max_map_count = 262144
```

Check OpenSearch pod logs:

```bash
kubectl logs -n <namespace> <opensearch-pod-name>
```

Should see successful startup without the vm.max_map_count error.

## Other OpenSearch Issues

### OpenSearch CrashLoopBackOff

**Check logs:**
```bash
kubectl logs -n <namespace> deployment/parsedmarc-opensearch
```

**Common causes:**
1. Insufficient memory - increase `opensearch.resources.limits.memory`
2. PVC not bound - check `kubectl get pvc`
3. Init container failed - check init container logs

### OpenSearch Pods Stuck in Pending

**Check:**
```bash
kubectl describe pod -n <namespace> <opensearch-pod-name>
```

**Common causes:**
1. No PV available - check storage class and PV provisioner
2. Node selector/affinity not matching - review node labels
3. Resource limits too high - nodes don't have enough CPU/memory

## parsedmarc Issues

### parsedmarc Cannot Connect to IMAP

**Symptoms:**
- Pod logs show connection errors
- Authentication failures

**Troubleshooting:**
```bash
# Check pod logs
kubectl logs -n <namespace> deployment/parsedmarc

# Verify secret is created
kubectl get secret -n <namespace> parsedmarc -o yaml

# Check if password was injected (from within pod)
kubectl exec -n <namespace> deployment/parsedmarc -- cat /tmp/parsedmarc.ini
```

**Common causes:**
1. Wrong IMAP credentials in values.yaml
2. IMAP server not accessible from cluster
3. Firewall blocking IMAP port (993)

### parsedmarc Cannot Connect to OpenSearch

**Check OpenSearch service:**
```bash
kubectl get svc -n <namespace> | grep opensearch
```

**Test connectivity from parsedmarc pod:**
```bash
kubectl exec -n <namespace> deployment/parsedmarc -- curl -v http://parsedmarc-opensearch:9200
```

**Common causes:**
1. OpenSearch not fully started yet
2. Wrong service name in values.yaml
3. Network policies blocking traffic

## General Kubernetes Issues

### ImagePullBackOff

**Check:**
```bash
kubectl describe pod -n <namespace> <pod-name>
```

**For custom parsedmarc image:**
1. Ensure image is built and pushed: `docker push ghcr.io/modalsource/parsedmarc-helm:latest`
2. Verify image repository in values.yaml matches
3. Check if authentication is needed for GHCR

### Insufficient Resources

**Check node resources:**
```bash
kubectl top nodes
kubectl describe nodes
```

**Reduce resource requests:**
```yaml
opensearch:
  resources:
    requests:
      cpu: 250m
      memory: 512Mi
```

## Getting Help

If issues persist:

1. Check full pod logs: `kubectl logs -f -n <namespace> <pod-name>`
2. Describe the resource: `kubectl describe pod/deployment/statefulset -n <namespace> <name>`
3. Check events: `kubectl get events -n <namespace> --sort-by='.lastTimestamp'`
4. Open an issue: https://github.com/modalsource/parsedmarc-helm/issues

## Pod Security Policy / Pod Security Standards Issues

### Error: "container's runAsUser breaks non-root policy"

**Cause:**
Your cluster enforces Pod Security Standards (PSS) or Pod Security Policies (PSP) that prevent running containers as root.

**Solution:**

The chart is configured to run OpenSearch as user 1000 (non-root) by default. If you still see this error:

1. **Check the sysctlInit container** - It needs to run as root (privileged) to set vm.max_map_count:

```yaml
opensearch:
  sysctlInit:
    enabled: false  # Disable if privileged containers not allowed
```

2. **Set vm.max_map_count on nodes instead** (see above section)

3. **For very strict PSS/PSP environments**, disable sysctlInit and use a DaemonSet or manual configuration

### Error: "containers must not set securityContext.privileged"

**Cause:**
The sysctlInit container requires privileged mode to set kernel parameters.

**Solution:**

Disable the init container and set vm.max_map_count manually on nodes:

```yaml
opensearch:
  sysctlInit:
    enabled: false
```

Then configure nodes as described in the vm.max_map_count section above.

### Pod Security Standards Compliance

For PSS `restricted` level:

```yaml
opensearch:
  # Disable privileged init container
  sysctlInit:
    enabled: false
  
  # Ensure non-root
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    fsGroup: 1000
  
  # Drop all capabilities
  securityContext:
    capabilities:
      drop:
        - ALL
```

Then use one of these approaches for vm.max_map_count:
- DaemonSet with hostPID (runs in kube-system, outside PSS scope)
- Manual node configuration
- Cloud provider node pool configuration
