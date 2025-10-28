# Kubernetes Workload Types Guide

## Overview

This guide explains the differences between Deployment, ReplicaSet, and DaemonSet, and when to use each.

---

## 1. Deployment (CURRENT - Recommended for most apps)

**What it is:**
- High-level controller that manages ReplicaSets
- Best for stateless applications
- Provides rolling updates and rollbacks

**Use cases:**
- Web applications (our Flask API)
- Microservices
- Stateless backends

**Current configuration:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: vault
spec:
  replicas: 1  # You control how many pods
  selector:
    matchLabels:
      app: vault
  template:
    # Pod template here
```

**Pros:**
- Easy rolling updates
- Rollback capability
- Self-healing (recreates failed pods)
- You specify exact number of replicas

**Cons:**
- Not ideal for node-level services

---

## 2. ReplicaSet (LOW-LEVEL - Rarely used directly)

**What it is:**
- Ensures a specified number of pod replicas are running
- Created automatically by Deployments
- Low-level primitive

**Use cases:**
- Almost never used directly
- Use Deployment instead (which creates ReplicaSet)

**Configuration:**
```yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: vault
spec:
  replicas: 1
  selector:
    matchLabels:
      app: vault
  template:
    # Pod template here
```

**Why avoid:**
- No rolling update support
- No rollback capability
- Deployment gives you ReplicaSet + more features

---

## 3. DaemonSet (For node-level services)

**What it is:**
- Runs **exactly ONE pod per node** (or per selected node)
- Automatically scales with cluster nodes
- Perfect for infrastructure services

**Use cases:**
- Log collectors (Fluentd, Filebeat)
- Monitoring agents (Prometheus Node Exporter)
- Network plugins (CNI)
- Storage drivers
- **NOT recommended for Vault** (single instance is fine)

**Configuration:**
```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: vault
  namespace: vault
spec:
  # NO replicas field - one per node automatically
  selector:
    matchLabels:
      app: vault
  template:
    metadata:
      labels:
        app: vault
    spec:
      nodeSelector:
        type: infrastructure  # Only on these nodes
      containers:
      - name: vault
        image: hashicorp/vault:1.15.4
        # ... rest of config
```

**Pros:**
- Automatic scaling with nodes
- Ensures service on every node
- Perfect for node-level operations

**Cons:**
- Can't specify replica count
- One pod per node (no more, no less)
- Not suitable for services like Vault that need single instance

---

## Comparison Table

| Feature | Deployment | ReplicaSet | DaemonSet |
|---------|-----------|------------|-----------|
| **Replica Control** | ✅ Specify count | ✅ Specify count | ❌ One per node |
| **Rolling Updates** | ✅ Yes | ❌ No | ✅ Yes |
| **Rollback** | ✅ Yes | ❌ No | ✅ Yes |
| **Node Affinity** | ✅ Optional | ✅ Optional | ✅ Built-in |
| **Auto-scale with nodes** | ❌ No | ❌ No | ✅ Yes |
| **Use Case** | Apps, APIs | N/A (use Deployment) | Node-level services |

---

## Recommendations for Our Project

### ✅ Keep as Deployment (Current):
- **Vault**: Single instance is fine (replicas: 1)
- **PostgreSQL**: Single instance with PVC (replicas: 1)
- **Flask API**: Multiple replicas for HA (replicas: 2)
- **ESO**: Single or few instances (replicas: 1)

### 🤔 Consider DaemonSet if:
- You need monitoring agents on every node
- You need log collectors on every node
- You have network plugins
- You have storage drivers

### ❌ Never use directly:
- **ReplicaSet**: Always use Deployment instead

---

## How to Convert

### Deployment → DaemonSet

**Changes needed:**
1. Change `kind: Deployment` to `kind: DaemonSet`
2. Remove `replicas:` field
3. Keep everything else the same

**Example:**
```bash
# Edit vault.yml
sed -i 's/kind: Deployment/kind: DaemonSet/' k8s/vault.yml
# Remove replicas line
sed -i '/replicas:/d' k8s/vault.yml
```

### DaemonSet → Deployment

**Changes needed:**
1. Change `kind: DaemonSet` to `kind: Deployment`
2. Add `replicas: 1` (or desired count)
3. Keep everything else the same

---

## Real-World Examples

### Deployment Example (Our API):
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: rohan-rest-api
spec:
  replicas: 2  # Run 2 pods for HA
  selector:
    matchLabels:
      app: rohan-rest-api
  template:
    # Pod spec
```

### DaemonSet Example (Monitoring):
```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: node-exporter
spec:
  # No replicas - runs on ALL nodes automatically
  selector:
    matchLabels:
      app: node-exporter
  template:
    # Pod spec
```

---

## Summary

**For our Student CRUD API project:**
- ✅ **Use Deployment** for: Vault, PostgreSQL, Flask API, ESO
- ❌ **Don't use ReplicaSet** directly
- 🤔 **Use DaemonSet** only if adding node-level monitoring/logging later

**Current setup is correct!** Deployment is the right choice for all our components.
