#!/bin/bash
# Ensure the kubesec-manifest ConfigMap exists for the kubesec scan step. Idempotent.
kubectl get ns cks-supply >/dev/null 2>&1 || kubectl create namespace cks-supply >/dev/null 2>&1
cat <<'YAML' >/tmp/kubesec-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: sample
spec:
  containers:
  - name: app
    image: nginx:1.25-alpine
YAML
kubectl -n cks-supply delete configmap kubesec-manifest --ignore-not-found >/dev/null 2>&1
kubectl -n cks-supply create configmap kubesec-manifest --from-file=pod.yaml=/tmp/kubesec-pod.yaml >/dev/null 2>&1
echo "kubesec-manifest ConfigMap ready in cks-supply"
