# Variables
APP_NAME=nodejs-app
DOCKER_REGISTRY=your-dockerhub-username
IMAGE_TAG=latest
K8S_NAMESPACE=default

# Paths
K8S_DIR=k8s
SONAR_PROJECT_KEY=nodejs-app

# Directory for monitoring manifests
MONITORING_DIR = monitoring


# Default target
all: test build docker push deploy

## Run unit tests with Mocha
test:
	@echo "Running unit tests..."
	cd app && npm install && npm test

## Run SonarQube code analysis
sonar:
	@echo "Running SonarQube analysis..."
	cd app && sonar-scanner \
	  -Dsonar.projectKey=$(SONAR_PROJECT_KEY) \
	  -Dsonar.sources=. \
	  -Dsonar.host.url=http://localhost:9000 \
	  -Dsonar.login=your-sonarqube-token

## Build the Node.js app Docker image
build:
	@echo "Building Docker image..."
	docker build -t $(DOCKER_REGISTRY)/$(APP_NAME):$(IMAGE_TAG) app/

## Push Docker image to registry
push:
	@echo "Pushing Docker image..."
	docker push $(DOCKER_REGISTRY)/$(APP_NAME):$(IMAGE_TAG)

## Deploy to Kubernetes
deploy:
	@echo "Deploying to Kubernetes..."
	kubectl apply -f $(K8S_DIR)/deployment.yaml -n $(K8S_NAMESPACE)
	kubectl apply -f $(K8S_DIR)/service.yaml -n $(K8S_NAMESPACE)

## Setup Monitoring (Prometheus + Grafana)
# monitoring:
# 	@echo "Setting up monitoring stack..."
# 	kubectl apply -f $(MONITORING_DIR)/prometheus.yaml -n monitoring
# 	kubectl apply -f (MONITORING_DIR)/grafana.yaml -n monitoring

# Install or upgrade Prometheus + Grafana via Helm
monitoring-install:
	helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
	helm repo update
	helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
		-f helm/kube-prometheus-values.yaml \
		-n monitoring --create-namespace

# Apply custom ServiceMonitor / PrometheusRule configs
monitoring-apply:
	kubectl apply -f $(K8S_DIR)/servicemonitor.yaml

# Delete monitoring stack
monitoring-delete:
	helm uninstall monitoring -n monitoring || true
	kubectl delete ns monitoring --ignore-not-found


## Clean Kubernetes resources
clean:
	@echo "Cleaning Kubernetes resources..."
	kubectl delete -f $(K8S_DIR)/deployment.yaml -n $(K8S_NAMESPACE) || true
	kubectl delete -f $(K8S_DIR)/service.yaml -n $(K8S_NAMESPACE) || true

.PHONY: all test sonar build push deploy monitoring clean
