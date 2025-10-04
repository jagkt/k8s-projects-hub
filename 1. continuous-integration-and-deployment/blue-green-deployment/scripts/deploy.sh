#!/bin/bash
set -e

ENVIRONMENT=${1:-staging}
COMMIT_HASH=${2:-latest}
KUBE_NAMESPACE="blue-green-$ENVIRONMENT"

echo "Deploying to $ENVIRONMENT environment"

# Load configuration
source ../config/environments.conf

deploy_namespace() {
    echo "Creating namespace $KUBE_NAMESPACE..."
    kubectl create namespace $KUBE_NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
}

deploy_configs() {
    echo "Deploying configurations..."
    kubectl apply -f ../kubernetes/configmap.yaml -n $KUBE_NAMESPACE
}

deploy_application() {
    local version=$1
    
    echo "Deploying $version version..."
    
    # Use Kustomize for environment-specific overlays
    if [ -d "../manifests/overlays/$ENVIRONMENT" ]; then
        kubectl apply -k ../manifests/overlays/$ENVIRONMENT
    else
        # Fallback to direct deployment
        kubectl apply -f ../kubernetes/namespace.yaml
        kubectl apply -f ../kubernetes/${version}-deployment.yaml -n $KUBE_NAMESPACE
        kubectl apply -f ../kubernetes/${version}-service.yaml -n $KUBE_NAMESPACE
    fi
    
    # Wait for rollout
    kubectl rollout status deployment/$APP_NAME-$version -n $KUBE_NAMESPACE --timeout=300s
    echo "$version deployment completed"
}

main() {
    deploy_namespace
    deploy_configs
    
    # Deploy both blue and green
    deploy_application "blue"
    deploy_application "green"
    
    # Deploy main service (initially pointing to blue)
    kubectl apply -f ../kubernetes/main-service.yaml -n $KUBE_NAMESPACE
    
    echo "Deployment to $ENVIRONMENT completed"
    echo "Status:"
    kubectl get all -n $KUBE_NAMESPACE
}

main "$@"