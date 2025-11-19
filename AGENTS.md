# Agent Instructions for parsedmarc-helm

## Build/Lint/Test Commands
- `helm lint charts/parsedmarc` - Lint the Helm chart
- `helm template charts/parsedmarc` - Test template rendering
- `helm install --dry-run --debug parsedmarc charts/parsedmarc` - Dry run installation
- `helm dependency update charts/parsedmarc` - Update chart dependencies
- `ct lint --all` - Lint all charts using chart-testing

## Code Style Guidelines
- **Structure**: Follow standard Helm chart structure (Chart.yaml, values.yaml, templates/)
- **Formatting**: Use 2-space indentation for YAML files
- **Naming**: Use kebab-case for template files (e.g., `config-map.yaml`, `deployment.yaml`)
- **Values**: Prefix all values with chart name to avoid conflicts (e.g., `parsedmarc.image.repository`)
- **Templates**: Use `{{- }}` for whitespace control, include helpers in `_helpers.tpl`
- **Comments**: Document all configurable values in values.yaml with inline comments
- **Labels**: Include standard Kubernetes labels (app.kubernetes.io/name, app.kubernetes.io/instance, etc.)
- **Dependencies**: Pin dependency versions in Chart.yaml (opensearch, opensearch-dashboards)
- **ConfigMaps**: Use checksums in deployment annotations to trigger rolling updates on config changes
- **Secrets**: Never hardcode sensitive values; use Kubernetes secrets or external secret managers

## Project Requirements
- parsedmarc deployment with ConfigMap for settings (email server, database, parsing options)
- Include opensearch and opensearch-dashboards as chart dependencies
- Build custom parsedmarc container image, store in GitHub Container Registry

## Development Plan
### Phase 1: Base Structure & Configuration (High Priority)
1. Create Helm chart directory structure (charts/parsedmarc/)
2. Create Chart.yaml with metadata and dependencies (opensearch, opensearch-dashboards)
3. Create values.yaml with parsedmarc, opensearch configurations and credentials
4. Create templates/_helpers.tpl with template helpers and standard labels

### Phase 2: Kubernetes Resources (High Priority)
5. Create ConfigMap template for parsedmarc configuration (email, database, parsing)
6. Create Secret template for sensitive credentials
7. Create Deployment template with checksum annotations for auto rolling updates
8. Create Service template to expose parsedmarc (if needed)

### Phase 3: Container Image (High/Medium Priority)
9. Create Dockerfile for custom parsedmarc image
10. Configure GitHub Actions for CI/CD (build and push to GHCR)

### Phase 4: Testing & Documentation (Medium/Low Priority)
11. Update chart dependencies (helm dependency update)
12. Test chart with helm lint and helm template
13. Create README.md with installation and configuration instructions
14. Final test with helm install --dry-run
