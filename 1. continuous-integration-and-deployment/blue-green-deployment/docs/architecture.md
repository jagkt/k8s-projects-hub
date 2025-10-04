# Architecture Overview

## Cluster Structure
- **Master Node**: 4GB RAM, 15GB Disk
- **Worker Node 1**: 4GB RAM, 30GB Disk  
- **Worker Node 2**: 4GB RAM, 30GB Disk

## Deployment Strategy
- **Blue Environment**: Stable production version
- **Green Environment**: New version for testing
- **Zero Downtime**: Traffic switching between environments

## Traffic Flow
User Request → NodePort (30007) → Main Service → Active Deployment (Blue/Green)