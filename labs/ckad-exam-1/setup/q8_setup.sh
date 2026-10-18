#!/bin/bash
# Seed the 'clip' deployment that the ClusterIP service (and Ingress) will target.
kubectl -n exam delete deployment clip --ignore-not-found >/dev/null 2>&1
cat <<'YAML' | kubectl apply -f - >/dev/null 2>&1
apiVersion: apps/v1
kind: Deployment
metadata:
  name: clip
  namespace: exam
spec:
  replicas: 2
  selector:
    matchLabels:
      app: clip
  template:
    metadata:
      labels:
        app: clip
    spec:
      containers:
      - name: web
        image: nginx:1.25
        ports:
        - containerPort: 80
YAML
echo "seeded deployment 'clip' (app=clip, port 80) in namespace exam"
