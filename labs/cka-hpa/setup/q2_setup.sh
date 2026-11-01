#!/bin/bash
# Seed the broken HPA scenario: Deployment 'api' WITHOUT a CPU request + an HPA
# targeting it -> the HPA can't compute utilization (<unknown>). Learner adds the request.
NS=hpa-learn
kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create namespace "$NS" >/dev/null 2>&1
kubectl -n "$NS" delete hpa api --ignore-not-found >/dev/null 2>&1
kubectl -n "$NS" delete deployment api --ignore-not-found >/dev/null 2>&1
kubectl -n "$NS" apply -f - >/dev/null 2>&1 <<'YAML'
apiVersion: apps/v1
kind: Deployment
metadata: { name: api, namespace: hpa-learn }
spec:
  replicas: 1
  selector: { matchLabels: { app: api } }
  template:
    metadata: { labels: { app: api } }
    spec:
      containers:
      - name: api
        image: nginx:1.25
YAML
kubectl -n "$NS" autoscale deployment api --cpu-percent=70 --min=1 --max=4 >/dev/null 2>&1
echo "seeded Deployment 'api' (no CPU request) + HPA 'api' stuck at <unknown> — fix the missing request"
