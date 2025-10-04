#!/bin/bash
set -e

ENVIRONMENT=${1:-production}
KUBE_NAMESPACE="blue-green-$ENVIRONMENT"

echo "Starting blue-green switch in $ENVIRONMENT"

# Load configuration
source ../config/environments.conf

get_current_version() {
    kubectl get service $APP_NAME-main-service -n $KUBE_NAMESPACE \
        -o jsonpath='{.spec.selector.version}' 2>/dev/null || echo "blue"
}

switch_traffic() {
    local current_version=$(get_current_version)
    local new_version="green"
    
    if [ "$current_version" == "green" ]; then
        new_version="blue"
    fi
    
    echo "Current version: $current_version"
    echo "Switching to: $new_version"
    
    # Update service selector
    kubectl patch service $APP_NAME-main-service -n $KUBE_NAMESPACE \
        -p "{\"spec\":{\"selector\":{\"version\":\"$new_version\"}}}"
    
    # Wait for switch to propagate
    sleep 10
    
    # Verify switch
    local updated_version=$(get_current_version)
    if [ "$updated_version" == "$new_version" ]; then
        echo "Successfully switched to $new_version"
    else
        echo "Switch failed"
        exit 1
    fi
}

run_smoke_tests() {
    echo "Running smoke tests..."
    local service_url=$(kubectl get service $APP_NAME-main-service -n $KUBE_NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    local node_port=$(kubectl get service $APP_NAME-main-service -n $KUBE_NAMESPACE -o jsonpath='{.spec.ports[0].nodePort}')
    
    if curl -s --retry 5 --retry-delay 2 http://$service_url:$node_port > /dev/null; then
        echo "Smoke tests passed"
    else
        echo "Smoke tests failed"
        exit 1
    fi
}

main() {
    switch_traffic
    run_smoke_tests
    
    echo "Blue-green switch completed successfully"
    echo "Application is now serving from $(get_current_version) version"
}

main "$@"