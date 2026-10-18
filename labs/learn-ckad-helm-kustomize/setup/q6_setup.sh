#!/bin/bash
# Setup for step 6 (Kustomize base): ensure namespace kustomize-learn exists
# (resource-level cleanup, NO ns delete) and (re)seed a clean base at
# /tmp/kustomize-ckad. Rewriting the base each time clears any leftover
# transforms from a previous step-7/8 attempt so the base starts pristine.
NS=kustomize-learn

kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create namespace "$NS" >/dev/null 2>&1

# Resource-level cleanup of objects this lab's kustomize steps create.
kubectl -n "$NS" delete deployment hello prod-hello --ignore-not-found >/dev/null 2>&1
kubectl -n "$NS" delete configmap prod-app-cfg app-cfg --ignore-not-found >/dev/null 2>&1

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

echo "seeded clean Kustomize base at /tmp/kustomize-ckad (namespace kustomize-learn ready)"
