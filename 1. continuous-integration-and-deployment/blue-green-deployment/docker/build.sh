#!/bin/bash
set -e

VERSION=${1:-all}
TAG=${2:-latest}

echo "Building Docker images"

build_version() {
    local version=$1
    local tag=$2
    
    echo "Building $version image..."
    docker build \
        -t $REGISTRY_URL/$APP_NAME-$version:$tag \
        -f docker/$version/Dockerfile \
        docker/$version/
    
    echo "Built $REGISTRY_URL/$APP_NAME-$version:$tag"
}

main() {
    source config/environments.conf
    
    if [ "$VERSION" = "all" ]; then
        build_version "blue" $TAG
        build_version "green" $TAG
    else
        build_version $VERSION $TAG
    fi
    
    echo "All images built successfully"
}

main "$@"