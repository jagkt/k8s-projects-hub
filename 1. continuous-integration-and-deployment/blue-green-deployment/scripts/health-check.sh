#!/bin/bash
set -e

ENVIRONMENT=${1:-staging}
KUBE_NAMESPACE="blue-green-$ENVIRONMENT"

echo "Running health checks for $ENVIRONMENT"

check_pods() {
    echo "Checking pod status..."
    local unhealthy_pods=$(kubectl get pods -n $KUBE_NAMESPACE -l app=$APP_NAME \
        --field-selector=status.phase!=Running -o name | wc -l)
    
    if [ "$unhealthy_pods" -gt 0 ]; then
        echo "Found $unhealthy_pods unhealthy pods"
        kubectl get pods -n $KUBE_NAMESPACE -l app=$APP_NAME
        exit 1
    fi
    echo "All pods are healthy"
}

check_services() {
    echo "Checking service endpoints..."
    kubectl get endpoints -n $KUBE_NAMESPACE -l app=$APP_NAME
}

check_readiness() {
    echo "Checking application readiness..."
    local current_version=$(kubectl get service $APP_NAME-main-service -n $KUBE_NAMESPACE \
        -o jsonpath='{.spec.selector.version}')
    
    local ready_pods=$(kubectl get deployment $APP_NAME-$current_version -n $KUBE_NAMESPACE \
        -o jsonpath='{.status.readyReplicas}')
    local desired_pods=$(kubectl get deployment $APP_NAME-$current_version -n $KUBE_NAMESPACE \
        -o jsonpath='{.status.replicas}')
    
    if [ "$ready_pods" != "$desired_pods" ]; then
        echo "Not all pods are ready ($ready_pods/$desired_pods)"
        exit 1
    fi
    echo "All pods are ready ($ready_pods/$desired_pods)"
}

main() {
    check_pods
    check_services
    check_readiness
    echo "All health checks passed"
}

main "$@"