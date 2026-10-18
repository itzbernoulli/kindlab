#!/bin/bash
# Seed the 'np' deployment that the NodePort service will target.
kubectl -n exam delete deployment np --ignore-not-found >/dev/null 2>&1
cat <<'YAML' | kubectl apply -f - >/dev/null 2>&1
apiVersion: apps/v1
kind: Deployment
metadata:
  name: np
  namespace: exam
spec:
  replicas: 2
  selector:
    matchLabels:
      app: np
  template:
    metadata:
      labels:
        app: np
    spec:
      containers:
      - name: web
        image: nginx:1.25
        ports:
        - containerPort: 80
YAML
echo "seeded deployment 'np' (app=np, port 80) in namespace exam"
