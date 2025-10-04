#!/bin/bash
set -e

ENVIRONMENT=${1:-production}
KUBE_NAMESPACE="blue-green-$ENVIRONMENT"

echo "Initiating rollback in $ENVIRONMENT"

rollback_deployment() {
    local version=$1
    echo "Rolling back $version deployment..."
    kubectl rollout undo deployment/$APP_NAME-$version -n $KUBE_NAMESPACE
    kubectl rollout status deployment/$APP_NAME-$version -n $KUBE_NAMESPACE --timeout=300s
}

switch_to_blue() {
    echo "Switching traffic to blue version..."
    kubectl patch service $APP_NAME-main-service -n $KUBE_NAMESPACE \
        -p '{"spec":{"selector":{"version":"blue"}}}'
    echo "Traffic switched to blue version"
}

main() {
    # Always rollback to blue (stable) version
    rollback_deployment "blue"
    rollback_deployment "green"
    switch_to_blue
    
    echo "Rollback completed successfully"
    echo "Current status:"
    kubectl get all -n $KUBE_NAMESPACE
}

main "$@"