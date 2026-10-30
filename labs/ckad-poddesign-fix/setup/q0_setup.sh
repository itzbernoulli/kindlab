#!/bin/bash
# Prepare pod-design: clean the pods this lab builds, and seed a BROKEN Deployment
# 'diag' (readiness probe on the wrong port) for the step-9 diagnose-and-fix.
NS=pod-design
kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create namespace "$NS" >/dev/null 2>&1
kubectl -n "$NS" delete pod sidecar-pod init-pod log-pod health-pod graceful-pod secure-pod qos-pod downward-pod \
  --ignore-not-found --force --grace-period=0 >/dev/null 2>&1
kubectl -n "$NS" delete deployment diag --ignore-not-found >/dev/null 2>&1

# Broken on purpose: nginx serves on 80, but the readiness probe hits 8080 -> never Ready.
kubectl -n "$NS" apply -f - >/dev/null 2>&1 <<'YAML'
apiVersion: apps/v1
kind: Deployment
metadata: { name: diag, labels: { app: diag } }
spec:
  replicas: 1
  selector: { matchLabels: { app: diag } }
  template:
    metadata: { labels: { app: diag } }
    spec:
      containers:
      - name: web
        image: nginx:1.25
        readinessProbe:
          httpGet: { path: /, port: 8080 }
          periodSeconds: 5
YAML
echo "pod-design ready; broken Deployment 'diag' seeded (won't go Ready — diagnose & fix in step 9)"
