# parsedmarc Helm Chart

A Helm chart for deploying [parsedmarc](https://github.com/domainaware/parsedmarc) on Kubernetes with OpenSearch and OpenSearch Dashboards.

parsedmarc is a Python-based DMARC report analyzer that parses DMARC aggregate and forensic reports, stores them in databases, and provides visualization through dashboards.

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- PV provisioner support in the underlying infrastructure (for OpenSearch persistence)

## Installing the Chart

### Add Helm Repository

Add the Helm repository hosted on GitHub Pages:

```bash
helm repo add parsedmarc https://modalsource.github.io/parsedmarc-helm
helm repo update
```

### Install from Repository

To install the chart with the release name `parsedmarc`:

```bash
helm install parsedmarc parsedmarc/parsedmarc \
  --set parsedmarc.imap.host=imap.example.com \
  --set parsedmarc.imap.user=dmarc@example.com \
  --set parsedmarc.imap.password=yourpassword
```

Or create a `values.yaml` file with your configuration:

```bash
helm install parsedmarc parsedmarc/parsedmarc -f values.yaml
```

### Install from Source

Alternatively, install directly from the source:

```bash
git clone https://github.com/modalsource/parsedmarc-helm.git
cd parsedmarc-helm
helm dependency update charts/parsedmarc
helm install parsedmarc charts/parsedmarc -f values.yaml
```

## Configuration

### Required Configuration

You must configure at least the IMAP settings to receive DMARC reports:

```yaml
parsedmarc:
  imap:
    host: "imap.example.com"
    port: 993
    user: "dmarc@example.com"
    password: "your-secure-password"
```

### Container Image

Before deploying, you need to build and push the Docker image:

```bash
# Build the image
docker build -t ghcr.io/your-org/parsedmarc:latest docker/

# Push to GitHub Container Registry
docker push ghcr.io/your-org/parsedmarc:latest
```

Then update the values.yaml:

```yaml
parsedmarc:
  image:
    repository: ghcr.io/your-org/parsedmarc
    tag: latest
```

### Optional: SMTP Configuration

To send email notifications:

```yaml
parsedmarc:
  smtp:
    host: "smtp.example.com"
    port: 587
    user: "notifications@example.com"
    password: "smtp-password"
    from: "dmarc-reports@example.com"
    to:
      - "security-team@example.com"
```

### OpenSearch Configuration

OpenSearch is enabled by default. To customize:

```yaml
opensearch:
  enabled: true
  replicas: 3
  persistence:
    enabled: true
    size: 20Gi
  resources:
    requests:
      cpu: 1000m
      memory: 2Gi
```

### OpenSearch Dashboards Configuration

Access dashboards to visualize DMARC reports:

```yaml
opensearch-dashboards:
  enabled: true
  service:
    type: LoadBalancer  # or NodePort, or use Ingress
    port: 5601
```

## Accessing OpenSearch Dashboards

After installation, get the service URL:

```bash
kubectl get svc parsedmarc-opensearch-dashboards-dashboards
```

For LoadBalancer:
```bash
export SERVICE_IP=$(kubectl get svc parsedmarc-opensearch-dashboards-dashboards -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "http://$SERVICE_IP:5601"
```

For NodePort:
```bash
export NODE_PORT=$(kubectl get svc parsedmarc-opensearch-dashboards-dashboards -o jsonpath='{.spec.ports[0].nodePort}')
export NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[0].address}')
echo "http://$NODE_IP:$NODE_PORT"
```

## Uninstalling the Chart

To uninstall/delete the `parsedmarc` deployment:

```bash
helm uninstall parsedmarc
```

## Parameters

### parsedmarc Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `parsedmarc.image.repository` | parsedmarc image repository | `ghcr.io/your-org/parsedmarc` |
| `parsedmarc.image.tag` | parsedmarc image tag | `latest` |
| `parsedmarc.replicaCount` | Number of parsedmarc replicas | `1` |
| `parsedmarc.imap.host` | IMAP server host | `""` |
| `parsedmarc.imap.port` | IMAP server port | `993` |
| `parsedmarc.imap.user` | IMAP username | `""` |
| `parsedmarc.imap.password` | IMAP password | `""` |
| `parsedmarc.imap.watch` | Watch for new messages | `true` |
| `parsedmarc.imap.delete` | Delete messages after processing | `false` |
| `parsedmarc.opensearch.enabled` | Enable OpenSearch output | `true` |
| `parsedmarc.opensearch.host` | OpenSearch host | `parsedmarc-opensearch` |

### OpenSearch Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `opensearch.enabled` | Enable OpenSearch | `true` |
| `opensearch.replicas` | Number of OpenSearch replicas | `1` |
| `opensearch.persistence.enabled` | Enable persistence | `true` |
| `opensearch.persistence.size` | Persistent volume size | `8Gi` |

## Development

### Linting

```bash
helm lint charts/parsedmarc
```

### Template Testing

```bash
helm template parsedmarc charts/parsedmarc
```

### Dry Run

```bash
helm install --dry-run --debug parsedmarc charts/parsedmarc
```

## License

This Helm chart is open source and available under the Apache License 2.0.
