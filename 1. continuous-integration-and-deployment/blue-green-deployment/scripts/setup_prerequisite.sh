#!/bin/bash

set -e

echo "Setting up prerequisites for Blue-Green Deployment"

# Source configuration
source ../config/environment.conf

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[WARN] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
    exit 1
}

# Verify Kubernetes cluster
log "Verifying Kubernetes cluster..."
kubectl cluster-info || error "Kubernetes cluster not accessible"
kubectl get nodes || error "Cannot list cluster nodes"

# Check if Docker is running
log "Checking Docker status..."
docker version >/dev/null 2>&1 || error "Docker not running"

# Setup local registry
log "Setting up local Docker registry..."
docker run -d -p 5000:5000 --name registry --restart=always registry:2 || warn "Registry might already be running"

# Update worker nodes with insecure registry
log "Configuring worker nodes for insecure registry..."
cat > /tmp/daemon.json << EOF
{
  "insecure-registries": ["${REGISTRY_IP}:5000"]
}
EOF

# Note: This part would need to be run on each worker node
log "Please run the following on each worker node:"
echo "echo '{\"insecure-registries\": [\"${REGISTRY_IP}:5000\"]}' > /etc/docker/daemon.json"
echo "rc-service docker restart"

log "Prerequisites setup completed successfully!"