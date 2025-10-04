#!/bin/bash

set -e

echo "Blue-Green Deployment Switch"

source ../config/environment.conf

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

NAMESPACE="blue-green-demo"
SERVICE="myapp-main-service"

# Get current active version
CURRENT_VERSION=$(kubectl get svc $SERVICE -n $NAMESPACE -o jsonpath='{.spec.selector.version}')
echo "Current active version: $CURRENT_VERSION"

if [ "$CURRENT_VERSION" == "blue" ]; then
    NEW_VERSION="green"
    echo -e "${GREEN}Switching from BLUE to GREEN deployment${NC}"
else
    NEW_VERSION="blue"
    echo -e "${BLUE}Switching from GREEN to BLUE deployment${NC}"
fi

# Confirm switch
read -p "Are you sure you want to switch to $NEW_VERSION? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Switch cancelled."
    exit 0
fi

# Perform switch
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

log "Initiating traffic switch..."
kubectl patch service $SERVICE -n $NAMESPACE -p "{\"spec\":{\"selector\":{\"version\":\"$NEW_VERSION\"}}}"

# Wait for switch to propagate
log "Waiting for traffic switch to complete..."
sleep 10

# Verify switch
UPDATED_VERSION=$(kubectl get svc $SERVICE -n $NAMESPACE -o jsonpath='{.spec.selector.version}')
if [ "$UPDATED_VERSION" == "$NEW_VERSION" ]; then
    log "Successfully switched to $NEW_VERSION version"
else
    echo "Switch failed"
    exit 1
fi

# Test the new version
log "Testing new version..."
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
curl -s http://$NODE_IP:30007 | grep -q "<title>" && echo "Application is responding"

log "Blue-Green switch completed successfully!"
echo -e "${YELLOW}Active version: $NEW_VERSION${NC}"
echo "Access at: http://$NODE_IP:30007"