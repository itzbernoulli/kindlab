#!/bin/bash
# Re-seed step 5: a Deployment whose readiness probe path is wrong (0 available).
NS=ckad-observability
kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create namespace "$NS" >/dev/null 2>&1
kubectl delete deployment ready-web -n "$NS" --ignore-not-found >/dev/null 2>&1
cat <<'YAML' | kubectl apply -n "$NS" -f - >/dev/null 2>&1
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ready-web
  labels:
    app: ready-web
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ready-web
  template:
    metadata:
      labels:
        app: ready-web
    spec:
      containers:
      - name: web
        image: nginx:1.25-alpine
        ports:
        - containerPort: 80
        readinessProbe:
          httpGet:
            path: /healthz
            port: 80
          initialDelaySeconds: 2
          periodSeconds: 3
YAML
echo "seeded Deployment 'ready-web' with a failing readiness probe (0 available) in $NS"
