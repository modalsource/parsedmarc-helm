# parsedmarc Docker Image

Custom Docker image for parsedmarc with enhanced secrets management.

This Docker image includes a custom entrypoint script to handle password injection for parsedmarc.

## Problem

parsedmarc reads configuration from an INI file and does not support reading sensitive values (passwords, tokens) from environment variables. This is problematic for Kubernetes deployments where secrets should be passed via environment variables, not stored in ConfigMaps.

## Solution

The `entrypoint.sh` script:

1. Copies the base configuration from `/etc/parsedmarc/parsedmarc.ini` (mounted from ConfigMap) to `/tmp/parsedmarc.ini`
2. Reads sensitive values from environment variables
3. Injects them into the appropriate sections of the config file
4. Starts parsedmarc with the modified configuration

## Supported Environment Variables

- `IMAP_PASSWORD` - Injected into `[imap]` section as `password =`
- `SMTP_PASSWORD` - Injected into `[smtp]` section as `password =`
- `SPLUNK_TOKEN` - Injected into `[splunk_hec]` section as `token =`

## Testing

Run the test script to verify password injection works correctly:

```bash
bash docker/test-entrypoint.sh
```

## Building

```bash
docker build -t ghcr.io/modalsource/parsedmarc-helm:latest docker/
```

## Running Locally

```bash
docker run -it \
  -e IMAP_PASSWORD=mypassword \
  -v $(pwd)/config:/etc/parsedmarc:ro \
  ghcr.io/modalsource/parsedmarc-helm:latest
```

## Kubernetes Deployment

The Helm chart automatically:
- Mounts the ConfigMap with parsedmarc.ini to `/etc/parsedmarc`
- Passes secrets as environment variables
- The entrypoint merges them at runtime
