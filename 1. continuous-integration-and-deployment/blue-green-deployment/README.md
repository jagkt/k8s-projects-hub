# Blue-Green Kubernetes Deployment

A complete blue-green deployment setup for Kubernetes on Alpine VMs.

## Prerequisites
- Kubernetes cluster with 3 nodes (1 master, 2 workers)
- Alpine Linux VMs
- Docker installed on all nodes
- kubectl configured on master

## Quick Start

1. **Setup Prerequisites:**
   ```bash
   chmod +x scripts/*.sh
   ./scripts/01-setup-prerequisites.sh




Usage Instructions
Extract the zip file to your master node

Update configuration: Edit config/environment.conf with your master node IP

Make scripts executable: chmod +x scripts/*.sh

Run in sequence:

./scripts/01-setup-prerequisites.sh

./scripts/02-build-push-images.sh

./scripts/03-deploy-blue.sh

./scripts/04-deploy-green.sh



# Blue-Green Kubernetes Deployment Project

This project demonstrates a blue-green deployment strategy on a Kubernetes cluster running on Alpine Linux VMs.

## Project Overview

Blue-green deployment is a technique that reduces downtime by running two identical production environments: Blue (current stable version) and Green (new version). Traffic is switched from Blue to Green once the new version is verified.

## Prerequisites

- Kubernetes cluster with 3 nodes (1 master, 2 workers)
- Alpine Linux VMs
- Docker installed on all nodes
- kubectl configured on master node
- Master node IP: 192.168.1.100 (update in config/settings.conf)

<!-- ## Quick Start Guide

### Step 1: Initial Setup
```bash
chmod +x scripts/*.sh
./scripts/01-setup.sh



Step 2: Build Docker Images
bash
./scripts/02-build-images.sh
Step 3: Deploy Blue Environment
bash
./scripts/03-deploy-blue.sh
Step 4: Deploy Green Environment
bash
./scripts/04-deploy-green.sh
Step 5: Switch Traffic
bash
./scripts/switch-traffic.sh
Architecture
Blue Deployment: Version 1.0 - Stable production environment

Green Deployment: Version 2.0 - New version for testing

Main Service: Routes traffic between blue and green environments

Local Registry: Docker registry running on master node

Access Points
Application URL: http://<worker-node-ip>:30007

Registry: http://192.168.1.100:5000

Maintenance
Rollback Procedure
bash
./scripts/rollback.sh
Cleanup
bash
./scripts/cleanup.sh
File Structure
docker-images/: Contains Dockerfiles and web content for both versions

kubernetes/: Kubernetes manifest files for deployments and services

scripts/: Automation scripts for deployment and management

config/: Configuration files with environment variables

Troubleshooting
Check cluster status: kubectl get nodes

Verify pods: kubectl get pods -A

Check services: kubectl get svc -A

View logs: kubectl logs <pod-name>

Support
For issues related to this deployment, check the Kubernetes logs and ensure all prerequisites are met before running the scripts. -->