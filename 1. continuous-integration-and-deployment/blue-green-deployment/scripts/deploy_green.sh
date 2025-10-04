#!/bin/bash

set -e

echo "Deploying Green environment"

source ../config/environment.conf

# Colors
GREEN='\033[0;32m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

# Substitute environment variables
log "Preparing Green deployment manifest..."
envsubst < ../kubernetes-manifests/green-deployment.yaml > /tmp/green-deployment.yaml

# Deploy Green
log "Deploying Green environment..."
kubectl apply -f /tmp/green-deployment.yaml

# Wait for deployment
log "Waiting for Green pods to be ready..."
kubectl rollout status deployment/myapp-green -n blue-green-demo --timeout=180s

log "Green deployment completed!"
echo "Green version is now running alongside Blue"
echo "Use blue-green-switch.sh to switch traffic"

# Show status
kubectl get pods -n blue-green-demo -l app=myapp