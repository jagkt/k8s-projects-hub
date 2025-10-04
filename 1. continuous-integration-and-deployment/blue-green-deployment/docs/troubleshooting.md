# Troubleshooting Guide

Contact Information
Cluster Admin: [Name] - [Contact]

Application Team: [Name] - [Contact]

Emergency Pager: [Number]

Last Updated: $(date +%Y-%m-%d)

```text

This comprehensive troubleshooting guide covers:

1. **Quick diagnosis commands** for immediate issues
2. **Common issues** with symptoms, causes, and solutions
3. **Specific scenarios** for pods, services, deployments, registry, resources, and network
4. **Pipeline-specific issues** for CI/CD
5. **Debugging techniques** from cluster level to pod level
6. **Prevention best practices**
7. **Emergency procedures** for critical situations
```
The guide provides copy-paste solutions for the most common problems you'll encounter with blue-green deployments on your Alpine Kubernetes cluster.


## Quick Diagnosis Commands

```bash
# Overall cluster status
make status

# Check all resources in namespace
kubectl get all -n blue-green-demo

# View recent events
kubectl get events -n blue-green-demo --sort-by=.lastTimestamp

# Check pod status and reasons
kubectl get pods -n blue-green-demo -o wide
```


## Common Issues and Solutions
1. Pod Issues
**Pods in ImagePullBackOff state**
Symptoms:

```text
NAME                          READY   STATUS             RESTARTS   AGE
myapp-blue-5f8c6b4d8c-abcde   0/1     ImagePullBackOff   0          2m
```

Causes:
Docker registry inaccessible
Invalid image name or tag
Authentication issues

Solutions:
```bash
# Check image name
kubectl describe pod <pod-name> -n blue-green-demo

# Verify image exists in registry
docker pull your-registry.com/blue-green-app-blue:latest

# Check registry secrets
kubectl get secrets -n blue-green-demo

# For local registry, ensure workers can access it
curl http://your-master-ip:5000/v2/_catalog
```
**Pods in CrashLoopBackOff state**
Symptoms:
```text
NAME                          READY   STATUS             RESTARTS   AGE
myapp-blue-5f8c6b4d8c-abcde   0/1     CrashLoopBackOff   5          3m
```
Causes:
Application crashing on startup
Configuration errors
Resource constraints

Solutions:
```bash
# Check application logs
kubectl logs <pod-name> -n blue-green-demo --previous

# Describe pod for more details
kubectl describe pod <pod-name> -n blue-green-demo

# Check resource limits
kubectl top pods -n blue-green-demo

# Test the Docker image locally
docker run your-registry.com/blue-green-app-blue:latest
```
**Pods in Pending state**
Symptoms:
```text
NAME                          READY   STATUS    RESTARTS   AGE
myapp-blue-5f8c6b4d8c-abcde   0/1     Pending   0          5m
```
Causes:
Insufficient cluster resources
Node selector issues
Persistent volume claims pending

Solutions:
```bash
# Check why pod is pending
kubectl describe pod <pod-name> -n blue-green-demo

# Check node resources
kubectl describe nodes

# Check for taints and tolerations
kubectl get nodes -o custom-columns=NAME:.metadata.name,TAINTS:.spec.taints
```

2. Service Issues
**Service not routing traffic**
Symptoms:
HTTP 503 errors
Connection timeouts
Wrong version being served

Solutions:
```bash
# Check service endpoints
kubectl get endpoints -n blue-green-demo

# Verify service selector matches pod labels
kubectl describe service myapp-main-service -n blue-green-demo
kubectl get pods -n blue-green-demo --show-labels

# Check current active version
kubectl get service myapp-main-service -n blue-green-demo -o jsonpath='{.spec.selector.version}'

# Test service internally
kubectl run curl-test --image=curlimages/curl -it --rm -- curl http://myapp-main-service.blue-green-demo.svc.cluster.local
```

**NodePort not accessible**
Symptoms:
Cannot access application via NodePort
Connection refused

Solutions:
```bash
# Get NodePort information
kubectl get service myapp-main-service -n blue-green-demo

# Check if NodePort is open on worker nodes
curl http://<worker-node-ip>:<node-port>

# Check firewall rules
sudo iptables -L | grep <node-port>

# Port forward for testing
kubectl port-forward service/myapp-main-service 8080:80 -n blue-green-demo
```

3. Deployment Issues
**Deployment stuck**
Symptoms:
```text
NAME                        READY   UP-TO-DATE   AVAILABLE   AGE
myapp-blue                  1/2     2            1           10m
```

Solutions:
```bash
# Check deployment status
kubectl describe deployment myapp-blue -n blue-green-demo

# Check rollout status
kubectl rollout status deployment/myapp-blue -n blue-green-demo --timeout=300s

# View deployment history
kubectl rollout history deployment/myapp-blue -n blue-green-demo
```

**Blue-Green switch not working**
Symptoms:
Traffic not switching between versions
Stuck on one version

Solutions:
```bash
# Check current service configuration
kubectl get service myapp-main-service -n blue-green-demo -o yaml

# Manually switch traffic
make switch

# Verify both deployments are healthy
make health

# Check if both versions have ready pods
kubectl get pods -n blue-green-demo -l app=blue-green-app
```

4. Registry Issues
**Local registry problems**
Symptoms:
"Connection refused" to registry
"manifest unknown" errors

Solutions:
```bash
# Check if registry is running
docker ps | grep registry

# Restart registry if needed
docker restart registry

# Verify registry content
curl http://localhost:5000/v2/_catalog

# Check worker node registry configuration
# On each worker, ensure /etc/docker/daemon.json has:
# { "insecure-registries": ["your-master-ip:5000"] }
```

5. Resource Issues
**Out of memory/CPU**

Symptoms:
Pods being evicted
"OOMKilled" status
Slow performance

Solutions:
```bash
# Check resource usage
kubectl top nodes
kubectl top pods -n blue-green-demo

# Adjust resource limits in deployment files
# Edit kubernetes/blue-deployment.yaml and kubernetes/green-deployment.yaml

# Scale down if needed
kubectl scale deployment myapp-blue --replicas=1 -n blue-green-demo
```

**Disk pressure**
Symptoms:
"Evicted" pods due to disk pressure
Image garbage collection issues

Solutions:
```bash
# Check disk space on nodes
kubectl describe nodes | grep -A 5 "Allocated resources"

# Clean up unused images
make clean-images

# Prune unused Kubernetes resources
kubectl get all --all-namespaces | grep -v "kube-system"
```

6. Network Issues
**DNS resolution problems**
Symptoms:
"Temporary failure in name resolution"
Services can't communicate

Solutions:
```bash
# Test DNS resolution inside cluster
kubectl run dns-test --image=busybox -it --rm -- nslookup kubernetes.default

# Check CoreDNS pods
kubectl get pods -n kube-system -l k8s-app=kube-dns

# Verify network policies
kubectl get networkpolicies -n blue-green-demo
```

**Service discovery issues**
Symptoms:
Services can't find each other
Inter-pod communication failing

Solutions:
```bash
# Verify service DNS
kubectl run test-pod --image=busybox -it --rm -- nslookup myapp-main-service.blue-green-demo

# Check service endpoints
kubectl get endpoints -n blue-green-demo

# Test network connectivity between pods
kubectl run ping-test --image=busybox -it --rm -- ping <pod-ip>
```

**Pipeline-Specific Issues**
**GitHub Actions Failures**
**Authentication failures**

```bash
# Check secrets are set in GitHub
# Verify DOCKER_USERNAME, DOCKER_PASSWORD, KUBECONFIG

# Test registry login manually
docker login -u $DOCKER_USERNAME -p $DOCKER_PASSWORD $REGISTRY_URL
```
Kubernetes context issues
```bash
# Verify kubeconfig is valid
kubectl config view

# Check current context
kubectl config current-context

# Test cluster access
kubectl cluster-info
```
Makefile Issues
Command not found
```bash
# Ensure Make is installed
make --version

# On Alpine Linux:
apk add make

# Check file permissions
chmod +x scripts/*.sh
```
Variable not set
```bash
# Set environment variables
export REGISTRY_URL=your-registry.com
export KUBE_NAMESPACE=blue-green-demo

# Or override in command
make deploy REGISTRY_URL=localhost:5000
```

Debugging Techniques
Step-by-Step Debugging
Check Cluster Level:

```bash
kubectl get nodes
kubectl cluster-info
```
Check Namespace Level:
```bash
kubectl get all -n blue-green-demo
kubectl get events -n blue-green-demo
```

Check Pod Level:
```bash
kubectl describe pod <pod-name> -n blue-green-demo
kubectl logs <pod-name> -n blue-green-demo
```

Check Service Level:
```bash
kubectl describe service <service-name> -n blue-green-demo
kubectl get endpoints -n blue-green-demo
```

Advanced Debugging
Network debugging

```bash
# Start a debug pod with networking tools
kubectl run debug-pod --image=nicolaka/netshoot -it --rm -- /bin/bash

# Inside debug pod:
curl -v http://myapp-main-service:80
nslookup myapp-main-service
ping <pod-ip>
```
Resource debugging
```bash
# Check resource quotas
kubectl describe resourcequotas -n blue-green-demo

# Check limit ranges
kubectl describe limitranges -n blue-green-demo

# Monitor real-time resource usage
kubectl top pods -n blue-green-demo --watch
```

Prevention Best Practices
Regular Maintenance
```bash
# Weekly cleanup
make clean-all

# Monitor resource usage
kubectl top nodes

# Update images regularly
docker system prune -a
```

Health Checks
```bash
# Regular health checks
make health

# Automated monitoring
kubectl get pods -n blue-green-demo --watch

# Log monitoring
make logs-blue
```

Backup Procedures
```bash
# Export current configurations
kubectl get all -n blue-green-demo -o yaml > backup.yaml

# Save Docker images
docker save -o blue-backup.tar your-registry.com/blue-green-app-blue:latest
```

Emergency Procedures
Immediate Rollback
```bash
# One-command rollback
make rollback

# Manual rollback if Makefile fails
kubectl patch service myapp-main-service -n blue-green-demo -p '{"spec":{"selector":{"version":"blue"}}}'
```

Complete Reset
```bash
# Delete everything and start fresh
make clean-all
make setup
make deploy
```

