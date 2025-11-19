# Releasing a New Helm Chart Version

This document explains how to release a new version of the parsedmarc Helm chart to GitHub Pages.

## Prerequisites

1. GitHub Pages must be enabled in repository settings (see `.github/SETUP.md`)
2. You must have push access to the repository

## Automatic Release Process

The chart is automatically released when changes are pushed to the `charts/` directory. The workflow:

1. Detects changes in `charts/` directory
2. Packages the Helm chart
3. Creates a GitHub Release with the chart `.tgz` file
4. Updates the `gh-pages` branch with the Helm repository index

## Release Methods

### Method 1: Using the Release Script (Recommended)

The easiest way to release a new version:

```bash
# Bump to a new version
./scripts/release.sh 0.2.0

# The script will:
# - Validate version format (semver)
# - Update Chart.yaml
# - Show you the diff
# - Ask for confirmation
# - Commit and push changes
```

### Method 2: Manual Version Bump

```bash
# 1. Edit Chart.yaml and update version
vim charts/parsedmarc/Chart.yaml

# Change this line:
# version: 0.1.0
# To:
# version: 0.2.0

# 2. Commit and push
git add charts/parsedmarc/Chart.yaml
git commit -m "Release Helm chart version 0.2.0"
git push

# The GitHub Actions workflow will automatically run
```

### Method 3: Manual Workflow Trigger

Trigger the workflow without making changes (useful for republishing):

**Using GitHub UI:**
1. Go to https://github.com/modalsource/parsedmarc-helm/actions
2. Click "Release Helm Chart" workflow
3. Click "Run workflow"
4. Select branch: `main`
5. Click "Run workflow"

**Using GitHub CLI:**
```bash
gh workflow run helm-release.yml
```

## Versioning Guidelines

Follow [Semantic Versioning](https://semver.org/):

- **MAJOR** version (X.0.0): Incompatible API changes
- **MINOR** version (0.X.0): New functionality (backwards compatible)
- **PATCH** version (0.0.X): Bug fixes (backwards compatible)

Examples:
- `0.1.0` → `0.1.1` - Bug fix
- `0.1.0` → `0.2.0` - New feature
- `0.1.0` → `1.0.0` - Breaking change

## Verify the Release

After pushing:

1. **Check Workflow Status:**
   - https://github.com/modalsource/parsedmarc-helm/actions
   - Wait for "Release Helm Chart" to complete (usually 1-2 minutes)

2. **Verify GitHub Release:**
   - https://github.com/modalsource/parsedmarc-helm/releases
   - Should see new release with chart `.tgz` file

3. **Test Helm Repository:**
   ```bash
   helm repo add parsedmarc https://modalsource.github.io/parsedmarc-helm
   helm repo update
   helm search repo parsedmarc
   ```

   Should show the new version:
   ```
   NAME                    CHART VERSION   APP VERSION     DESCRIPTION
   parsedmarc/parsedmarc   0.2.0          8.12.0          A Helm chart for parsedmarc...
   ```

## Troubleshooting

### Workflow Doesn't Trigger
- Ensure changes are in `charts/` directory
- Check if workflow is enabled in Actions tab
- Verify GitHub Pages is configured (Settings → Pages)

### Release Already Exists
- The workflow uses `skip_existing: true`
- Bump the version in `Chart.yaml` to create a new release
- Delete the old release first, or increment the version

### Chart Not Showing in Helm Repo
- Wait a few minutes for GitHub Pages to update
- Check `gh-pages` branch exists: https://github.com/modalsource/parsedmarc-helm/tree/gh-pages
- Verify `index.yaml` was updated in `gh-pages` branch
- Try clearing Helm cache: `helm repo update`

## What Gets Released

Each release includes:

1. **GitHub Release**
   - Tag: `parsedmarc-<version>` (e.g., `parsedmarc-0.2.0`)
   - Chart package: `parsedmarc-<version>.tgz`
   - Automatically generated release notes

2. **Helm Repository** (`gh-pages` branch)
   - Chart package in root directory
   - Updated `index.yaml` with chart metadata

## First-Time Setup

If this is the first release:

1. Enable GitHub Pages:
   - Settings → Pages
   - Source: `gh-pages` branch
   - Folder: `/ (root)`

2. Trigger first release:
   ```bash
   ./scripts/release.sh 0.1.0
   ```

3. Wait for workflow to complete

4. Verify GitHub Pages is live:
   - https://modalsource.github.io/parsedmarc-helm/index.yaml
