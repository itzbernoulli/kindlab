#!/bin/bash
# Resource-level reset. Seeds target Deployments (with requests) + a 'broke' one (no requests + a pre-made HPA) for step 5.
NS=hpa-learn
kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create namespace "$NS" >/dev/null 2>&1
kubectl -n "$NS" delete deployment web api cache worker broke --ignore-not-found >/dev/null 2>&1
kubectl -n "$NS" delete hpa web-hpa api-hpa cache-hpa worker-hpa broke-hpa --ignore-not-found >/dev/null 2>&1
dep(){ # $1=name
kubectl -n "$NS" apply -f - >/dev/null 2>&1 <<YAML
apiVersion: apps/v1
kind: Deployment
metadata: { name: $1, namespace: hpa-learn, labels: { app: $1 } }
spec:
  replicas: 1
  selector: { matchLabels: { app: $1 } }
  template:
    metadata: { labels: { app: $1 } }
    spec:
      containers:
      - name: web
        image: nginx:1.25
        resources: { requests: { cpu: 100m, memory: 64Mi }, limits: { cpu: 200m, memory: 128Mi } }
YAML
}
for d in web api cache worker; do dep "$d"; done
# step 5: a Deployment WITHOUT requests + an HPA already pointing at it (will read <unknown>)
kubectl -n "$NS" apply -f - >/dev/null 2>&1 <<'YAML'
apiVersion: apps/v1
kind: Deployment
metadata: { name: broke, namespace: hpa-learn, labels: { app: broke } }
spec:
  replicas: 1
  selector: { matchLabels: { app: broke } }
  template:
    metadata: { labels: { app: broke } }
    spec: { containers: [ { name: web, image: nginx:1.25 } ] }
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata: { name: broke-hpa, namespace: hpa-learn }
spec:
  scaleTargetRef: { apiVersion: apps/v1, kind: Deployment, name: broke }
  minReplicas: 1
  maxReplicas: 5
  metrics:
  - type: Resource
    resource: { name: cpu, target: { type: Utilization, averageUtilization: 50 } }
YAML
echo "hpa-learn ready: Deployments web/api/cache/worker (with requests) + broke (no requests) & broke-hpa seeded for step 5"
