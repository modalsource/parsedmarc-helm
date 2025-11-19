#!/bin/bash

echo "================================================"
echo "  parsedmarc-helm Environment Check"
echo "================================================"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

check_pass() {
  echo -e "${GREEN}✓${NC} $1"
}

check_fail() {
  echo -e "${RED}✗${NC} $1"
}

check_warn() {
  echo -e "${YELLOW}⚠${NC} $1"
}

# Check kubectl
echo "Checking kubectl..."
if command -v kubectl &> /dev/null; then
  KUBECTL_VERSION=$(kubectl version --client --short 2>/dev/null | cut -d' ' -f3)
  check_pass "kubectl installed: $KUBECTL_VERSION"
else
  check_fail "kubectl not found"
  exit 1
fi
echo ""

# Check Helm
echo "Checking Helm..."
if command -v helm &> /dev/null; then
  HELM_VERSION=$(helm version --short | cut -d'+' -f1)
  check_pass "Helm installed: $HELM_VERSION"
else
  check_fail "Helm not found"
  exit 1
fi
echo ""

# Check cluster connection
echo "Checking Kubernetes cluster connection..."
if kubectl cluster-info &> /dev/null; then
  CLUSTER=$(kubectl config current-context 2>/dev/null)
  check_pass "Connected to cluster: $CLUSTER"
else
  check_fail "Cannot connect to Kubernetes cluster"
  exit 1
fi
echo ""

# Check nodes
echo "Checking Kubernetes nodes..."
NODE_COUNT=$(kubectl get nodes --no-headers 2>/dev/null | wc -l | tr -d ' ')
if [ "$NODE_COUNT" -gt 0 ]; then
  check_pass "Found $NODE_COUNT node(s)"
  kubectl get nodes
else
  check_fail "No nodes found"
fi
echo ""

# Check vm.max_map_count on nodes
echo "Checking vm.max_map_count on nodes..."
NODES=$(kubectl get nodes -o jsonpath='{.items[*].metadata.name}')
for NODE in $NODES; do
  echo "  Checking node: $NODE"
  
  # Try to check via debug pod
  MAX_MAP=$(kubectl debug node/$NODE -it --image=busybox:latest -- sysctl vm.max_map_count 2>/dev/null | grep -o '[0-9]*' | tail -1)
  
  if [ -z "$MAX_MAP" ]; then
    check_warn "Cannot check vm.max_map_count on node $NODE (need node access)"
    echo "    You may need to enable sysctlInit or set manually"
  elif [ "$MAX_MAP" -ge 262144 ]; then
    check_pass "vm.max_map_count = $MAX_MAP (sufficient)"
  else
    check_warn "vm.max_map_count = $MAX_MAP (too low, needs >= 262144)"
    echo "    Enable sysctlInit in values or set manually on nodes"
  fi
done
echo ""

# Check storage classes
echo "Checking storage classes..."
STORAGE_CLASSES=$(kubectl get storageclass --no-headers 2>/dev/null | wc -l | tr -d ' ')
if [ "$STORAGE_CLASSES" -gt 0 ]; then
  check_pass "Found $STORAGE_CLASSES storage class(es)"
  kubectl get storageclass
else
  check_fail "No storage classes found - OpenSearch needs persistent storage"
fi
echo ""

# Check for privileged pod support (for sysctlInit)
echo "Checking privileged container support..."
cat <<PODEOF | kubectl apply --dry-run=client -f - &>/dev/null
apiVersion: v1
kind: Pod
metadata:
  name: test-privileged
spec:
  containers:
  - name: test
    image: busybox
    securityContext:
      privileged: true
PODEOF

if [ $? -eq 0 ]; then
  check_pass "Privileged containers allowed (sysctlInit will work)"
else
  check_warn "Privileged containers may be restricted"
  echo "    If deployment fails, set vm.max_map_count manually on nodes"
fi
echo ""

# Summary
echo "================================================"
echo "  Summary"
echo "================================================"
echo ""
echo "Prerequisites check complete!"
echo ""
echo "Next steps:"
echo "1. Build and push Docker image:"
echo "   docker build -t ghcr.io/modalsource/parsedmarc-helm:latest docker/"
echo "   docker push ghcr.io/modalsource/parsedmarc-helm:latest"
echo ""
echo "2. Create values.yaml with your IMAP credentials"
echo ""
echo "3. Install the chart:"
echo "   helm install parsedmarc charts/parsedmarc -f values.yaml"
echo ""
echo "For issues, see: TROUBLESHOOTING.md"
