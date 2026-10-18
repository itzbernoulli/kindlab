#!/bin/bash
# Setup for step 4 (Kustomize): drop a base at /tmp/kustomize-ckad on the host and
# ensure the target namespace exists. Idempotent: rewrites the base each time so a
# leftover namePrefix from a previous step-5 attempt is cleared.

kubectl delete namespace kustomize-learn --ignore-not-found --wait=false >/dev/null 2>&1
for i in $(seq 1 30); do
  kubectl get ns kustomize-learn >/dev/null 2>&1 && { sleep 1; continue; }
  break
done
kubectl create namespace kustomize-learn >/dev/null 2>&1

mkdir -p /tmp/kustomize-ckad

cat > /tmp/kustomize-ckad/deployment.yaml <<'YAML'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hello
spec:
  replicas: 1
  selector:
    matchLabels:
      app: hello
  template:
    metadata:
      labels:
        app: hello
    spec:
      containers:
      - name: hello
        image: nginx:alpine
        ports:
        - containerPort: 80
YAML

cat > /tmp/kustomize-ckad/kustomization.yaml <<'YAML'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: kustomize-learn
resources:
- deployment.yaml
YAML

echo "seeded Kustomize base at /tmp/kustomize-ckad (namespace kustomize-learn ready)"
