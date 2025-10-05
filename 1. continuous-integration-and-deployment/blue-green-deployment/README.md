
# Blue-Green Kubernetes Deployment Project

This project demonstrates a blue-green deployment strategy on a Kubernetes cluster running on Alpine Linux VMs. this also include an automated muliti-pipeline implementation for Kubernetes with zero downtime.

## Project Overview

Blue-green deployment is a technique that reduces downtime by running two identical production environments: Blue (current stable version) and Green (new version). Traffic is switched from Blue to Green once the new version is verified.

## Prerequisites

- Kubernetes cluster with 3 nodes (1 master, 2 workers)
- Alpine Linux VMs
- Docker installed on all nodes
- kubectl configured on master

## Pipeline Features

Stages:  Test --> Build --> Deploy --> Verify --> Switch

- Automated testing and building
- Parallel blue/green image builds
- Zero-downtime deployments: Blue-green switching
- Automated traffic switching
- Health checks and rollback
- Multi-environment support
- Slack/email notifications
- Environment Management: Staging and production

The pipeline automatically handles the entire blue-green deployment process with proper testing, verification, and rollback capabilities.


## Supported CI/CD Platforms

- GitHub Actions
- GitLab CI
- Jenkins

## Quick Start

**Configure Environment:**
   ```bash
   cp config/environments.conf.example config/environments.conf
   # Edit with your settings
   ```

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

