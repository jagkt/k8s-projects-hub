# Makefile Usage Guide

## Overview
The Makefile provides a consistent interface for all blue-green deployment operations.

## Quick Start

```bash
# Show all available commands
make help

# Setup environment
make setup

# Build both versions
make build

# Deploy to staging
make deploy-staging

# Switch traffic
make switch-staging

# Check status
make status