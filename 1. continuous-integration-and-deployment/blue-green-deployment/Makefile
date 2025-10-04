# Blue-Green Kubernetes CI/CD Makefile
# Usage: make <target>

# Configuration
PROJECT_NAME ?= blue-green-app
REGISTRY_URL ?= localhost:5000
KUBE_NAMESPACE ?= blue-green-demo
ENVIRONMENT ?= staging
VERSION ?= blue
COMMIT_HASH ?= $(shell git rev-parse --short HEAD)

# Colors for output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[0;33m
BLUE := \033[0;34m
NC := \033[0m

.PHONY: help setup build test deploy switch rollback clean status logs

help: ## Display this help message
	@echo "Blue-Green Kubernetes Deployment Targets:"
	@echo ""
	@echo "Project: ${PROJECT_NAME}"
	@echo "Registry: ${REGISTRY_URL}"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

## Development Targets
setup: ## Setup development environment
	@echo "${BLUE} Setting up development environment...${NC}"
	@chmod +x scripts/*.sh
	@./scripts/ci-setup.sh
	@echo "${GREEN} Setup completed${NC}"

dependencies: ## Install project dependencies
	@echo "${BLUE} Installing dependencies...${NC}"
	@pip install -r requirements.txt
	@echo "${GREEN} Dependencies installed${NC}"

validate: ## Validate Kubernetes manifests
	@echo "${BLUE} Validating Kubernetes manifests...${NC}"
	@kubectl apply --dry-run=client -f kubernetes/ -n ${KUBE_NAMESPACE}
	@kustomize build manifests/overlays/staging/ > /dev/null
	@echo "${GREEN} Manifests validated${NC}"

## Build Targets
build: build-blue build-green ## Build both blue and green images

build-blue: ## Build blue version Docker image
	@echo "${BLUE} Building blue image...${NC}"
	@./scripts/build-push.sh blue ${COMMIT_HASH}

build-green: ## Build green version Docker image
	@echo "${GREEN} Building green image...${NC}"
	@./scripts/build-push.sh green ${COMMIT_HASH}

build-version: ## Build specific version (make build-version VERSION=blue)
	@echo "${YELLOW} Building ${VERSION} image...${NC}"
	@./scripts/build-push.sh ${VERSION} ${COMMIT_HASH}

## Test Targets
test: test-manifests test-images ## Run all tests

test-manifests: ## Test Kubernetes manifests
	@echo "${BLUE} Testing Kubernetes manifests...${NC}"
	@kubectl apply --dry-run=server -f kubernetes/ -n ${KUBE_NAMESPACE}
	@echo "${GREEN} Manifest tests passed${NC}"

test-images: ## Test Docker images
	@echo "${BLUE} Testing Docker images...${NC}"
	@docker run --rm ${REGISTRY_URL}/${PROJECT_NAME}-blue:latest nginx -t
	@docker run --rm ${REGISTRY_URL}/${PROJECT_NAME}-green:latest nginx -t
	@echo "${GREEN} Image tests passed${NC}"

## Deployment Targets
deploy: deploy-blue deploy-green ## Deploy both blue and green versions

deploy-blue: ## Deploy blue version only
	@echo "${BLUE} Deploying blue version...${NC}"
	@kubectl apply -f kubernetes/namespace.yaml
	@kubectl apply -f kubernetes/blue-deployment.yaml -n ${KUBE_NAMESPACE}
	@kubectl rollout status deployment/${PROJECT_NAME}-blue -n ${KUBE_NAMESPACE} --timeout=300s
	@echo "${GREEN} Blue deployment completed${NC}"

deploy-green: ## Deploy green version only
	@echo "${GREEN} Deploying green version...${NC}"
	@kubectl apply -f kubernetes/namespace.yaml
	@kubectl apply -f kubernetes/green-deployment.yaml -n ${KUBE_NAMESPACE}
	@kubectl rollout status deployment/${PROJECT_NAME}-green -n ${KUBE_NAMESPACE} --timeout=300s
	@echo "${GREEN} Green deployment completed${NC}"

deploy-staging: ## Deploy to staging environment
	@echo "${YELLOW} Deploying to staging...${NC}"
	@./scripts/deploy.sh staging ${COMMIT_HASH}

deploy-production: ## Deploy to production environment
	@echo "${RED} Deploying to production...${NC}"
	@./scripts/deploy.sh production ${COMMIT_HASH}

deploy-service: ## Deploy main service
	@echo "${BLUE} Deploying main service...${NC}"
	@kubectl apply -f kubernetes/main-service.yaml -n ${KUBE_NAMESPACE}
	@echo "${GREEN} Service deployed${NC}"

## Blue-Green Operations
switch: ## Switch traffic between blue and green
	@echo "${YELLOW} Switching traffic...${NC}"
	@./scripts/blue-green-switch.sh ${ENVIRONMENT}

switch-staging: ## Switch traffic in staging
	@echo "${YELLOW} Switching staging traffic...${NC}"
	@./scripts/blue-green-switch.sh staging

switch-production: ## Switch traffic in production
	@echo "${RED} Switching production traffic...${NC}"
	@./scripts/blue-green-switch.sh production

rollback: ## Rollback to previous version
	@echo "${RED} Rolling back deployment...${NC}"
	@./scripts/rollback.sh ${ENVIRONMENT}

## Monitoring & Debugging
status: ## Check deployment status
	@echo "${BLUE} Deployment Status:${NC}"
	@kubectl get all -n ${KUBE_NAMESPACE}
	@echo ""
	@echo "${BLUE} Service Endpoints:${NC}"
	@kubectl get endpoints -n ${KUBE_NAMESPACE}
	@echo ""
	@echo "${BLUE} Current Active Version:${NC}"
	@kubectl get service ${PROJECT_NAME}-main-service -n ${KUBE_NAMESPACE} -o jsonpath='{.spec.selector.version}' 2>/dev/null || echo "Not found"

logs: ## Tail logs from current active version
	@echo "${BLUE} Tailing logs...${NC}"
	@kubectl logs -f deployment/${PROJECT_NAME}-blue -n ${KUBE_NAMESPACE} &

logs-blue: ## Tail logs from blue version
	@echo "${BLUE} Tailing blue logs...${NC}"
	@kubectl logs -f deployment/${PROJECT_NAME}-blue -n ${KUBE_NAMESPACE}

logs-green: ## Tail logs from green version
	@echo "${GREEN} Tailing green logs...${NC}"
	@kubectl logs -f deployment/${PROJECT_NAME}-green -n ${KUBE_NAMESPACE}

health: ## Run health checks
	@echo "${BLUE} Running health checks...${NC}"
	@./scripts/health-check.sh ${ENVIRONMENT}

metrics: ## Show deployment metrics
	@echo "${BLUE} Deployment Metrics:${NC}"
	@echo "Blue replicas: $$(kubectl get deployment ${PROJECT_NAME}-blue -n ${KUBE_NAMESPACE} -o jsonpath='{.status.readyReplicas}')"
	@echo "Green replicas: $$(kubectl get deployment ${PROJECT_NAME}-green -n ${KUBE_NAMESPACE} -o jsonpath='{.status.readyReplicas}')"
	@echo "Active version: $$(kubectl get service ${PROJECT_NAME}-main-service -n ${KUBE_NAMESPACE} -o jsonpath='{.spec.selector.version}' 2>/dev/null || echo 'unknown')"

## Cleanup Targets
clean: clean-pods clean-services ## Clean up all resources

clean-pods: ## Delete all pods
	@echo "${YELLOW} Cleaning up pods...${NC}"
	@kubectl delete pods --all -n ${KUBE_NAMESPACE} --wait=false 2>/dev/null || true

clean-services: ## Delete all services
	@echo "${YELLOW} Cleaning up services...${NC}"
	@kubectl delete services --all -n ${KUBE_NAMESPACE} --wait=false 2>/dev/null || true

clean-all: ## Complete cleanup (namespace and all resources)
	@echo "${RED} Complete cleanup...${NC}"
	@kubectl delete namespace ${KUBE_NAMESPACE} --wait=false 2>/dev/null || true
	@docker system prune -f

clean-images: ## Clean up Docker images
	@echo "${YELLOW} Cleaning up Docker images...${NC}"
	@docker image prune -af

## CI/CD Integration
ci-setup: ## CI-specific setup
	@echo "${BLUE} CI Setup...${NC}"
	@./scripts/ci-setup.sh

ci-build: ## CI build step
	@echo "${BLUE} CI Build...${NC}"
	@make build
	@make test

ci-deploy: ## CI deploy step
	@echo "${BLUE} CI Deploy...${NC}"
	@make deploy-staging
	@make health

ci-full: ## Full CI pipeline
	@echo "${BLUE} Running full CI pipeline...${NC}"
	@make ci-setup
	@make ci-build
	@make ci-deploy
	@echo "${GREEN} CI pipeline completed${NC}"

## Utility Targets
port-forward: ## Port forward to main service
	@echo "${BLUE} Port forwarding to service...${NC}"
	@kubectl port-forward service/${PROJECT_NAME}-main-service 8080:80 -n ${KUBE_NAMESPACE}

describe: ## Describe all resources
	@echo "${BLUE} Describing resources...${NC}"
	@kubectl describe all -n ${KUBE_NAMESPACE}

events: ## Show recent events
	@echo "${BLUE} Recent events...${NC}"
	@kubectl get events -n ${KUBE_NAMESPACE} --sort-by=.lastTimestamp

version: ## Show version information
	@echo "${BLUE} Version Information:${NC}"
	@echo "Project: ${PROJECT_NAME}"
	@echo "Commit: ${COMMIT_HASH}"
	@echo "Registry: ${REGISTRY_URL}"
	@echo "Namespace: ${KUBE_NAMESPACE}"

## Quick Commands
prod-deploy: build deploy-production switch-production ## Quick production deployment
	@echo "${GREEN} Production deployment completed${NC}"

quick-switch: switch ## Quick traffic switch
	@echo "${GREEN} Traffic switched${NC}"

quick-rollback: rollback ## Quick rollback
	@echo "${GREEN} Rollback completed${NC}"