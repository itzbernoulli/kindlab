#!/bin/bash
# Reset the learn environment to a clean, idempotent slate.
kubectl delete namespace ckad-config --ignore-not-found --wait=false >/dev/null 2>&1
# wait for the namespace to be fully gone so recreation is clean
for i in $(seq 1 30); do kubectl get ns ckad-config >/dev/null 2>&1 || break; sleep 1; done
kubectl create namespace ckad-config >/dev/null 2>&1
# seed the ConfigMap used by step 1
kubectl -n ckad-config create configmap app-cfg \
  --from-literal=APP_COLOR=blue \
  --from-literal=APP_MODE=prod >/dev/null 2>&1
# seed the Secret used by step 2
kubectl -n ckad-config create secret generic db-cred \
  --from-literal=DB_USER=admin \
  --from-literal=DB_PASS=s3cr3t >/dev/null 2>&1
echo "ckad-config ready (configmap app-cfg, secret db-cred seeded)"
