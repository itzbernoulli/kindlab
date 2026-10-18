#!/bin/bash
# Setup for step 9 (diagnose & fix): seed a BROKEN kustomization at
# /tmp/kustomize-broken whose resources: names a file that does not exist
# (deploy.yaml), while the real manifest on disk is deployment.yaml.
# `kubectl apply -k` fails to build until the learner fixes the resources entry.
# Namespace kustomize-learn is ensured at resource level (NO ns delete).
NS=kustomize-learn

kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create namespace "$NS" >/dev/null 2>&1
kubectl -n "$NS" delete deployment api --ignore-not-found >/dev/null 2>&1

rm -rf /tmp/kustomize-broken 2>/dev/null
mkdir -p /tmp/kustomize-broken

cat > /tmp/kustomize-broken/deployment.yaml <<'YAML'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api
spec:
  replicas: 1
  selector:
    matchLabels:
      app: api
  template:
    metadata:
      labels:
        app: api
    spec:
      containers:
      - name: api
        image: nginx:alpine
        ports:
        - containerPort: 80
YAML

# Broken on purpose: resources points at deploy.yaml, but the file is deployment.yaml.
cat > /tmp/kustomize-broken/kustomization.yaml <<'YAML'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: kustomize-learn
resources:
- deploy.yaml
YAML

echo "seeded BROKEN kustomization at /tmp/kustomize-broken (won't build — diagnose & fix in step 9)"
