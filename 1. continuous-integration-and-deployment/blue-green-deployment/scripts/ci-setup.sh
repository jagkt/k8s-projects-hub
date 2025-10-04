#!/bin/bash
set -e

echo "Setting up CI/CD environment"

# Load configuration
source ../config/environments.conf

setup_kubernetes() {
    echo "Setting up Kubernetes access..."
    mkdir -p ~/.kube
    cp ../config/kubeconfig ~/.kube/config
    chmod 600 ~/.kube/config
    
    # Verify cluster access
    kubectl cluster-info || exit 1
    echo "Kubernetes access configured"
}

setup_docker() {
    echo "Setting up Docker registry..."
    docker login -u $DOCKER_USERNAME -p $DOCKER_PASSWORD $REGISTRY_URL
    echo "Docker registry configured"
}

install_dependencies() {
    echo "Installing dependencies..."
    pip3 install -r ../requirements.txt 2>/dev/null || echo "No Python dependencies"
    echo "Dependencies installed"
}

main() {
    setup_kubernetes
    setup_docker
    install_dependencies
    echo "CI/CD setup completed"
}

main "$@"