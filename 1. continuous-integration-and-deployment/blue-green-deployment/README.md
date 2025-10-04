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






# Blue-Green Kubernetes CI/CD Pipeline

Automated blue-green deployment pipeline for Kubernetes with zero downtime.

## Prerequisites
- Kubernetes cluster with 3 nodes (1 master, 2 workers)
- Alpine Linux VMs
- Docker installed on all nodes
- kubectl configured on master

## Pipeline Features
Test --> Build --> Deploy --> Verify --> Switch
- Automated testing and building
- Parallel blue/green image builds
- Zero-downtime deployments
- Automated traffic switching
- Health checks and rollback
- Multi-environment support
- Slack/email notifications

## Pipeline Stages
Test --> Build --> Deploy --> Verify --> Switch

## Supported CI/CD Platforms

- GitHub Actions
- GitLab CI
- Jenkins

## Quick Start

1. **Configure Environment:**
   ```bash
   cp config/environments.conf.example config/environments.conf
   # Edit with your settings

## Manual Operation
```bash
# Deploy specific version
./scripts/deploy.sh staging <commit-hash>

# Switch traffic
./scripts/blue-green-switch.sh production

# Rollback
./scripts/rollback.sh production

# Health check
./scripts/health-check.sh staging
```



## This CI/CD pipeline provides:

1. **Automated Builds**: Parallel blue/green image building
2. **Zero-Downtime Deployments** - Blue-green switching
3. **Health Monitoring**: Automated health checks
4. **Rollback Capability**: One-click rollbacks
5. **Multi-Platform Support**: GitHub Actions, GitLab CI, Jenkins
6. **Notifications**: Slack/email alerts
7. **Environment Management**: Staging and production

The pipeline automatically handles the entire blue-green deployment process with proper testing, verification, and rollback capabilities.