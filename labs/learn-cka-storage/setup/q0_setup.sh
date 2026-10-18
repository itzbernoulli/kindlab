#!/bin/bash
# Reset the learn environment to a clean slate.
kubectl delete namespace storage-learn --ignore-not-found --wait=false >/dev/null 2>&1
kubectl delete pv pv-data --ignore-not-found --wait=false >/dev/null 2>&1
kubectl delete storageclass fast-local --ignore-not-found >/dev/null 2>&1
# clear the default annotation from any pre-existing class (e.g. kind's standard)
for sc in $(kubectl get sc -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' 2>/dev/null); do
  kubectl patch storageclass "$sc" \
    -p '{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}' >/dev/null 2>&1
done
# wait for namespace to be gone, then recreate it
for i in $(seq 1 20); do kubectl get ns storage-learn >/dev/null 2>&1 || break; sleep 1; done
kubectl create namespace storage-learn >/dev/null 2>&1
echo "storage-learn ready (no StorageClass/PV/PVC yet, no default class)"
