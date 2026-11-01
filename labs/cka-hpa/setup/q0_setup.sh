#!/bin/bash
# Prepare hpa-learn: seed Deployment 'web' WITH a CPU request (ready to autoscale).
# Resource-level cleanup only (never delete the namespace).
NS=hpa-learn
kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create namespace "$NS" >/dev/null 2>&1
kubectl -n "$NS" delete hpa web api --ignore-not-found >/dev/null 2>&1
kubectl -n "$NS" delete deployment web api --ignore-not-found >/dev/null 2>&1
kubectl -n "$NS" apply -f - >/dev/null 2>&1 <<'YAML'
apiVersion: apps/v1
kind: Deployment
metadata: { name: web, namespace: hpa-learn }
spec:
  replicas: 2
  selector: { matchLabels: { app: web } }
  template:
    metadata: { labels: { app: web } }
    spec:
      containers:
      - name: web
        image: nginx:1.25
        resources: { requests: { cpu: 100m } }
YAML
echo "hpa-learn ready (Deployment web seeded with a CPU request; hpa/api cleared)"
