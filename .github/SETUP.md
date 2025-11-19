# GitHub Pages Setup

To enable Helm chart publishing to GitHub Pages, you need to configure your repository:

## Steps

1. Go to your repository on GitHub: https://github.com/modalsource/parsedmarc-helm

2. Click on **Settings** → **Pages**

3. Under **Source**, select:
   - **Source**: Deploy from a branch
   - **Branch**: `gh-pages`
   - **Folder**: `/ (root)`

4. Click **Save**

## How It Works

- The `helm-release.yml` workflow automatically runs when changes are pushed to `charts/` directory
- It uses [chart-releaser](https://github.com/helm/chart-releaser-action) to:
  - Package the Helm chart
  - Create a GitHub release with the chart package
  - Update the `gh-pages` branch with the Helm repository index

## Using the Repository

Once GitHub Pages is enabled and the workflow runs successfully, users can add the repository:

```bash
helm repo add parsedmarc https://modalsource.github.io/parsedmarc-helm
helm repo update
helm install parsedmarc parsedmarc/parsedmarc
```

## Manual Trigger

You can manually trigger the release workflow:

1. Go to **Actions** tab
2. Select **Release Helm Chart** workflow
3. Click **Run workflow**
4. Select branch and click **Run workflow**
