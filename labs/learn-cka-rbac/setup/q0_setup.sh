#!/bin/bash
# Reset the learn environment to a clean slate.
kubectl delete namespace rbac-learn --ignore-not-found --wait=false >/dev/null 2>&1
kubectl delete clusterrole node-reader --ignore-not-found >/dev/null 2>&1
kubectl delete clusterrolebinding dev-nr --ignore-not-found >/dev/null 2>&1
kubectl delete csr learn-dev --ignore-not-found >/dev/null 2>&1
# wait for namespace to be gone, then recreate + seed the two configmaps
for i in $(seq 1 20); do kubectl get ns rbac-learn >/dev/null 2>&1 || break; sleep 1; done
kubectl create namespace rbac-learn >/dev/null 2>&1
kubectl -n rbac-learn create configmap app-config --from-literal=k=v >/dev/null 2>&1
kubectl -n rbac-learn create configmap other-config --from-literal=k=v >/dev/null 2>&1
echo "rbac-learn ready (configmaps app-config, other-config seeded)"
