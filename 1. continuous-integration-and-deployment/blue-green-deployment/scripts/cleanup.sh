#!/bin/bash
set -e

ENVIRONMENT=${1:-all}
DAYS_OLD=${2:-7}

echo "Cleaning up old resources"

cleanup_old_images() {
    echo "Cleaning up old Docker images..."
    docker image prune -a -f --filter "until=${DAYS_OLD}d"
}

cleanup_kubernetes() {
    local namespace=$1
    if [ "$namespace" != "all" ]; then
        echo "Cleaning up namespace: $namespace"
        kubectl delete namespace $namespace --ignore-not-found=true
    else
        echo "Cleaning up all blue-green namespaces..."
        kubectl get namespaces --no-headers -o custom-columns=":metadata.name" | grep blue-green | xargs -r kubectl delete namespace
    fi
}

cleanup_old_deployments() {
    echo "Cleaning up failed pods..."
    kubectl delete pods --field-selector=status.phase=Failed --all-namespaces
}

main() {
    cleanup_old_images
    cleanup_kubernetes $ENVIRONMENT
    cleanup_old_deployments
    echo "Cleanup completed"
}

main "$@"