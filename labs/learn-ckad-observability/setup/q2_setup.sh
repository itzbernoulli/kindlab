#!/bin/bash
# Re-seed step 2: a Deployment with a non-existent image tag (ImagePullBackOff).
NS=ckad-observability
kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create namespace "$NS" >/dev/null 2>&1
kubectl delete deployment web -n "$NS" --ignore-not-found >/dev/null 2>&1
cat <<'YAML' | kubectl apply -n "$NS" -f - >/dev/null 2>&1
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
  labels:
    app: web
spec:
  replicas: 1
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
      - name: web
        image: nginx:does-not-exist-9999
YAML
echo "seeded Deployment 'web' with a bad image tag (ImagePullBackOff) in $NS"
