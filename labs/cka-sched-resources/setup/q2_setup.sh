#!/bin/bash
# Seed a Deployment whose CPU request (6 cores) exceeds every node's allocatable
# (4 cores) -> the pod is unschedulable (Pending). Learner lowers the request.
NS=resources-learn
kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create namespace "$NS" >/dev/null 2>&1
kubectl -n "$NS" delete deployment hog --ignore-not-found >/dev/null 2>&1
kubectl -n "$NS" apply -f - >/dev/null 2>&1 <<'YAML'
apiVersion: apps/v1
kind: Deployment
metadata: { name: hog, namespace: resources-learn }
spec:
  replicas: 1
  selector: { matchLabels: { app: hog } }
  template:
    metadata: { labels: { app: hog } }
    spec:
      containers:
      - name: web
        image: nginx:1.25
        resources:
          requests: { cpu: "6", memory: 64Mi }
YAML
echo "seeded Deployment 'hog' requesting cpu:6 (> 4 allocatable) — Pending; diagnose & fix the request"
