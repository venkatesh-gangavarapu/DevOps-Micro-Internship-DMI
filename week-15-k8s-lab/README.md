# Week 15 — Kubernetes Lab

Hands-on Kubernetes lab covering the full lifecycle of workload management: from single Pods to production-grade Deployments, three Service types, health probes, and Horizontal Pod Autoscaling. Each section deliberately includes a broken configuration so you can observe failure modes and fix them.

---

## Lab Structure

```
week-15-k8s-lab/
├── pods/
│   └── nginx-pod.yml
├── replicasets/
│   └── nginx-replicaset.yml
├── deployments/
│   └── nginx-deployment.yaml
├── services/
│   ├── clusterip/
│   │   ├── 00-nginx-deploy.yaml
│   │   ├── 01-nginx-svc-clusterip.yaml
│   │   ├── 02-nginx-svc-selector-broken.yaml
│   │   ├── 03-deploy-backup.yaml
│   │   └── 03-readiness-broken.yaml
│   ├── nodeport/
│   │   ├── 00-nginx-deploy.yaml
│   │   └── 01-nginx-svc-nodeport.yaml
│   └── loadbalancer/
│       ├── 00-nginx-deploy.yaml
│       ├── 01-nginx-svc-loadbalancer.yaml
│       └── 02-readiness-broken.yaml
├── health-probes-liveness/
│   ├── 00-nginx-deploy-baseline.yaml
│   ├── 01-nginx-deploy-liveness.yaml
│   ├── 02-nginx-liveness-broken.yaml
│   └── 03-nginx-liveness-fixed.yaml
├── health-probes-readiness/
│   ├── 00-nginx-deploy-baseline.yaml
│   ├── 01-nginx-deploy-readiness.yaml
│   ├── 02-nginx-readiness-broken.yaml
│   ├── 03-nginx-readiness-fixed.yaml
│   └── 04-readiness-broken-patch.yaml
└── autoscaling/
    ├── autoscaling-deployment.yaml
    ├── hpa-deployment.yml
    └── hpa-nginx.yaml
```

---

## Prerequisites

- A running Kubernetes cluster (minikube, kind, or cloud-managed)
- `kubectl` configured and pointing to your cluster
- `metrics-server` installed for the autoscaling section

```bash
# Verify cluster access
kubectl cluster-info

# Install metrics-server (minikube)
minikube addons enable metrics-server
```

---

## Section 1 — Pods

**Path:** `pods/`

A Pod is the smallest deployable unit in Kubernetes — one or more containers sharing a network namespace.

```bash
kubectl apply -f pods/nginx-pod.yml
kubectl get pods
kubectl describe pod nginx-pod
kubectl delete -f pods/nginx-pod.yml
```

**Key takeaway:** Pods are ephemeral. If a Pod dies with no controller managing it, it stays dead. This is why ReplicaSets and Deployments exist.

---

## Section 2 — ReplicaSets

**Path:** `replicasets/`

A ReplicaSet ensures a specified number of Pod replicas are running at all times. The manifest creates **5 replicas** of nginx v1.21.1.

```bash
kubectl apply -f replicasets/nginx-replicaset.yml
kubectl get replicasets
kubectl get pods -l app=nginx

# Delete one pod manually — watch ReplicaSet self-heal
kubectl delete pod <pod-name>
kubectl get pods -l app=nginx
```

**Key takeaway:** ReplicaSets maintain desired state. However, they do not support rolling updates natively — use Deployments for that.

---

## Section 3 — Deployments

**Path:** `deployments/`

A Deployment wraps a ReplicaSet and adds declarative rolling updates, rollback, and revision history.

The manifest provisions **2 replicas** with:
- `RollingUpdate` strategy (`maxSurge: 1`, `maxUnavailable: 0` — zero-downtime rollout)
- Both liveness and readiness probes
- CPU requests (`100m`) and limits (`200m`)

```bash
kubectl apply -f deployments/nginx-deployment.yaml
kubectl get deployments
kubectl rollout status deployment/nginx-deployment

# Trigger a rolling update by changing the image tag
kubectl set image deployment/nginx-deployment nginx=nginx:1.23.0
kubectl rollout history deployment/nginx-deployment

# Roll back if something goes wrong
kubectl rollout undo deployment/nginx-deployment
```

---

## Section 4 — Services

Services provide stable network access to a dynamic set of Pods. Three service types are covered, progressing from cluster-internal to internet-facing.

### 4a. ClusterIP (internal access only)

**Path:** `services/clusterip/`

| File | Purpose |
|------|---------|
| `00-nginx-deploy.yaml` | Backing deployment |
| `01-nginx-svc-clusterip.yaml` | Working ClusterIP service |
| `02-nginx-svc-selector-broken.yaml` | Broken: selector `app: does-not-match` — no endpoints |
| `03-readiness-broken.yaml` | Broken readiness probe patch (path `/does-not-exist`) |

```bash
kubectl apply -f services/clusterip/00-nginx-deploy.yaml
kubectl apply -f services/clusterip/01-nginx-svc-clusterip.yaml
kubectl get svc nginx-service
kubectl get endpoints nginx-service   # should show pod IPs

# Apply the broken service — observe empty endpoints
kubectl apply -f services/clusterip/02-nginx-svc-selector-broken.yaml
kubectl get endpoints nginx-service-broken
```

**Key takeaway:** Service selectors must exactly match Pod labels. A mismatch silently produces zero endpoints.

---

### 4b. NodePort (external via node IP)

**Path:** `services/nodeport/`

Exposes the service on a static port (`30080`) on every node in the cluster.

```bash
kubectl apply -f services/nodeport/00-nginx-deploy.yaml
kubectl apply -f services/nodeport/01-nginx-svc-nodeport.yaml
kubectl get svc nginx-nodeport-service

# Access via minikube
minikube service nginx-nodeport-service --url

# Or directly
curl http://<node-ip>:30080
```

**Key takeaway:** NodePort is useful for local clusters or bare-metal, but exposes a high-numbered port. Cloud environments prefer LoadBalancer or Ingress.

---

### 4c. LoadBalancer (cloud-native external access)

**Path:** `services/loadbalancer/`

Provisions a cloud load balancer (AWS ELB, GCP LB, Azure LB) with an external IP. On minikube, run `minikube tunnel` to simulate.

```bash
kubectl apply -f services/loadbalancer/00-nginx-deploy.yaml
kubectl apply -f services/loadbalancer/01-nginx-svc-loadbalancer.yaml
kubectl get svc nginx-loadbalancer-service   # wait for EXTERNAL-IP

curl http://<external-ip>

# Apply the broken readiness probe — service gets no healthy endpoints
kubectl apply -f services/loadbalancer/02-readiness-broken.yaml
kubectl get endpoints nginx-loadbalancer-service
```

---

## Section 5 — Health Probes: Liveness

**Path:** `health-probes-liveness/`

Liveness probes detect when a container is stuck or deadlocked. Kubernetes **restarts** the container on failure.

| File | Probe path | Outcome |
|------|-----------|---------|
| `00-nginx-deploy-baseline.yaml` | None | No automatic recovery |
| `01-nginx-deploy-liveness.yaml` | `/` (valid) | Container restarted if unhealthy |
| `02-nginx-liveness-broken.yaml` | `/does-not-exit` | 404 → constant CrashLoopBackOff |
| `03-nginx-liveness-fixed.yaml` | `/` (valid) | Restored healthy behaviour |

```bash
# Deploy baseline (no probe)
kubectl apply -f health-probes-liveness/00-nginx-deploy-baseline.yaml

# Add correct liveness probe
kubectl apply -f health-probes-liveness/01-nginx-deploy-liveness.yaml
kubectl describe pod -l app=nginx | grep -A 10 "Liveness"

# Apply broken probe — watch restart count climb
kubectl apply -f health-probes-liveness/02-nginx-liveness-broken.yaml
kubectl get pods -w   # observe RESTARTS column

# Fix it
kubectl apply -f health-probes-liveness/03-nginx-liveness-fixed.yaml
```

**Probe config (01):**
- `initialDelaySeconds: 10` — grace period for container startup
- `periodSeconds: 10` — check every 10 s
- `failureThreshold: 3` — restart after 3 consecutive failures

---

## Section 6 — Health Probes: Readiness

**Path:** `health-probes-readiness/`

Readiness probes control whether a Pod receives traffic. Unlike liveness, a failed readiness probe does **not** restart the container — it only removes the Pod from the Service endpoints.

| File | Probe path | Outcome |
|------|-----------|---------|
| `00-nginx-deploy-baseline.yaml` | None | Pod gets traffic immediately |
| `01-nginx-deploy-readiness.yaml` | `/` (valid) | Traffic withheld until ready |
| `02-nginx-readiness-broken.yaml` | `/does-not-exit` | Pod never receives traffic |
| `03-nginx-readiness-fixed.yaml` | `/` (valid) | Traffic routing restored |
| `04-readiness-broken-patch.yaml` | `/does-not-exist` | Patch fragment (apply via kubectl patch) |

```bash
kubectl apply -f health-probes-readiness/00-nginx-deploy-baseline.yaml

kubectl apply -f health-probes-readiness/01-nginx-deploy-readiness.yaml
kubectl get pods   # STATUS shows 0/1 READY until probe passes

kubectl apply -f health-probes-readiness/02-nginx-readiness-broken.yaml
kubectl get endpoints   # empty — no healthy pods

kubectl apply -f health-probes-readiness/03-nginx-readiness-fixed.yaml
kubectl get endpoints   # pod IPs restored
```

**Probe config (01):**
- `initialDelaySeconds: 2` — faster feedback than liveness
- `periodSeconds: 5` — checked more frequently
- `successThreshold: 1` — single success marks pod as ready

---

## Section 7 — Horizontal Pod Autoscaling (HPA)

**Path:** `autoscaling/`

HPA scales the number of Pod replicas automatically based on observed CPU utilization. `metrics-server` must be running.

| File | Purpose |
|------|---------|
| `autoscaling-deployment.yaml` | Basic deployment demonstrating self-healing |
| `hpa-deployment.yml` | Deployment with CPU requests/limits (required for HPA) |
| `hpa-nginx.yaml` | HPA: min 2, max 5 replicas at 50% CPU threshold |

```bash
# Deploy with resource requests (mandatory for HPA)
kubectl apply -f autoscaling/hpa-deployment.yml

# Create the HPA
kubectl apply -f autoscaling/hpa-nginx.yaml
kubectl get hpa

# Simulate load to trigger scale-up
kubectl run load-generator --image=busybox --restart=Never -- \
  /bin/sh -c "while true; do wget -q -O- http://nginx-deployment; done"

kubectl get hpa -w   # watch REPLICAS column scale up
kubectl get pods     # observe new pods being created

# Remove load — HPA scales back down (may take a few minutes)
kubectl delete pod load-generator
```

**HPA spec:**
- Target: `nginx-deployment`
- Min replicas: **2** | Max replicas: **5**
- Metric: CPU utilization target **50%**

---

## Concepts Reference

| Concept | Resource | Behaviour on probe failure |
|---------|----------|--------------------------|
| Self-healing | ReplicaSet / Deployment | Recreates dead pods |
| Liveness probe | Pod spec | Restarts the container |
| Readiness probe | Pod spec | Removes pod from endpoints (no restart) |
| HPA | HorizontalPodAutoscaler | Scales replica count |

### Service type comparison

| Type | Accessible from | Use case |
|------|----------------|---------|
| ClusterIP | Inside cluster only | Internal microservice communication |
| NodePort | Node IP + port | Local clusters, bare-metal |
| LoadBalancer | External IP | Cloud environments |

---

## Instructor

**Pravin Mishra** — DevOps Micro Internship (DMI) Program
