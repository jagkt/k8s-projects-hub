#!/bin/bash

set -e

echo "Deploying Blue environment"

source ../config/environment.conf

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

# Create namespace
log "Creating namespace..."
kubectl apply -f ../kubernetes-manifests/namespace.yaml

# Substitute environment variables in manifests
log "Preparing Blue deployment manifest..."
envsubst < ../kubernetes-manifests/blue-deployment.yaml > /tmp/blue-deployment.yaml
envsubst < ../kubernetes-manifests/main-service.yaml > /tmp/main-service.yaml

# Deploy Blue
log "Deploying Blue environment..."
kubectl apply -f /tmp/blue-deployment.yaml

# Wait for deployment
log "Waiting for Blue pods to be ready..."
kubectl rollout status deployment/myapp-blue -n blue-green-demo --timeout=180s

# Deploy main service (pointing to Blue)
log "Deploying main service..."
kubectl apply -f /tmp/main-service.yaml

# Get access information
log "Blue deployment completed!"
echo -e "${BLUE}Access your application at: http://<worker-node-ip>:30007${NC}"
echo "Current active version: BLUE"

# Show status
kubectl get all -n blue-green-demo