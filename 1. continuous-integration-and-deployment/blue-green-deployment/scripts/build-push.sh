#!/bin/bash
set -e

VERSION=${1:-blue}
COMMIT_HASH=${2:-latest}
SOURCE_DIR="../docker/$VERSION"

echo "Building $VERSION version from commit $COMMIT_HASH"

# Load configuration
source ../config/environments.conf

build_image() {
    local version=$1
    local tag=$2
    
    echo "Building Docker image for $version..."
    docker build \
        -t $REGISTRY_URL/$APP_NAME-$version:$tag \
        -t $REGISTRY_URL/$APP_NAME-$version:latest \
        --build-arg COMMIT_HASH=$COMMIT_HASH \
        --build-arg BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ') \
        $SOURCE_DIR
        
    echo "Image built: $REGISTRY_URL/$APP_NAME-$version:$tag"
}

push_image() {
    local version=$1
    local tag=$2
    
    echo "Pushing image to registry..."
    docker push $REGISTRY_URL/$APP_NAME-$version:$tag
    docker push $REGISTRY_URL/$APP_NAME-$version:latest
    echo "Image pushed: $REGISTRY_URL/$APP_NAME-$version:$tag"
}

main() {
    if [[ ! "$VERSION" =~ ^(blue|green)$ ]]; then
        echo "Error: Version must be 'blue' or 'green'"
        exit 1
    fi
    
    build_image $VERSION $COMMIT_HASH
    push_image $VERSION $COMMIT_HASH
}

main "$@"