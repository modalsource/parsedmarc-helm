#!/bin/bash
set -e

CHART_FILE="charts/parsedmarc/Chart.yaml"

# Check if version is provided
if [ -z "$1" ]; then
  echo "Usage: ./scripts/release.sh <new-version>"
  echo "Example: ./scripts/release.sh 0.2.0"
  exit 1
fi

NEW_VERSION=$1

# Validate version format (semver)
if ! [[ $NEW_VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Error: Version must be in format X.Y.Z (e.g., 0.2.0)"
  exit 1
fi

# Get current version
CURRENT_VERSION=$(grep '^version:' $CHART_FILE | awk '{print $2}')
echo "Current version: $CURRENT_VERSION"
echo "New version: $NEW_VERSION"

# Update Chart.yaml
if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS
  sed -i '' "s/^version: .*/version: $NEW_VERSION/" $CHART_FILE
else
  # Linux
  sed -i "s/^version: .*/version: $NEW_VERSION/" $CHART_FILE
fi

echo "✓ Updated Chart.yaml"

# Show diff
git diff $CHART_FILE

# Confirm
read -p "Commit and push? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  git add $CHART_FILE
  git commit -m "Release Helm chart version $NEW_VERSION"
  git push
  echo ""
  echo "✓ Pushed to GitHub!"
  echo "The GitHub Actions workflow will automatically:"
  echo "  1. Package the Helm chart"
  echo "  2. Create a GitHub release"
  echo "  3. Update the gh-pages branch"
  echo ""
  echo "Check workflow status at:"
  echo "https://github.com/modalsource/parsedmarc-helm/actions"
else
  # Revert changes
  git checkout $CHART_FILE
  echo "✗ Release cancelled"
fi
