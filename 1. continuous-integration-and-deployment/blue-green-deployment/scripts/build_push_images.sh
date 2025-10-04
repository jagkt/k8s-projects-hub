#!/bin/bash

set -e

echo "Building and pushing Docker images"

source ../config/environment.conf

# Colors
GREEN='\033[0;32m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

# Build Blue image
log "Building Blue image (v1.0)..."
docker build -t ${REGISTRY_IP}:5000/myapp-blue:1.0 ../docker-images/blue/

# Build Green image  
log "Building Green image (v2.0)..."
docker build -t ${REGISTRY_IP}:5000/myapp-green:2.0 ../docker-images/green/

# Push images
log "Pushing images to registry..."
docker push ${REGISTRY_IP}:5000/myapp-blue:1.0
docker push ${REGISTRY_IP}:5000/myapp-green:2.0

# Verify images
log "Verifying images in registry..."
curl -s http://${REGISTRY_IP}:5000/v2/_catalog | jq .

log "Docker images built and pushed successfully!"