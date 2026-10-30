#!/bin/bash
# Prepare storage-learn with RESOURCE-LEVEL cleanup. We never drop the whole namespace
# (that races under load). Ensure the ns exists, remove this lab's objects, clear any
# stray default-class annotation, then seed a BROKEN PVC for the step-8 diagnose-and-fix.
NS=storage-learn
kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create namespace "$NS" >/dev/null 2>&1

# Pods first (they hold PVCs), then PVCs, then cluster-scoped PV/SC this lab creates.
kubectl -n "$NS" delete pod app sub-app dyn-app fix-consumer \
  --ignore-not-found --force --grace-period=0 >/dev/null 2>&1
kubectl -n "$NS" delete pvc pvc-data dyn-pvc broken-pvc \
  --ignore-not-found --force --grace-period=0 >/dev/null 2>&1
kubectl delete pv pv-data --ignore-not-found --wait=false >/dev/null 2>&1
kubectl delete storageclass fast-local --ignore-not-found >/dev/null 2>&1

# Clear the default-class annotation from every existing class (e.g. kind's 'standard'),
# so step 6 is a clean, single-default exercise.
for sc in $(kubectl get sc -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' 2>/dev/null); do
  kubectl patch storageclass "$sc" \
    -p '{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}' >/dev/null 2>&1
done

# PREREQUISITE (severed-chain reseed): the fix re-points broken-pvc at StorageClass
# 'fast-local', which the original mega-lab built in an earlier exercise now living
# in cka-storage-dynamic. Seed it here so the fix can actually bind.
kubectl apply -f - >/dev/null 2>&1 <<'YAML'
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-local
provisioner: rancher.io/local-path
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer
YAML

# Seed the step-8 fault: a PVC referencing a StorageClass that does not exist -> stays Pending.
kubectl -n "$NS" apply -f - >/dev/null 2>&1 <<'YAML'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: broken-pvc
  namespace: storage-learn
spec:
  accessModes:
  - ReadWriteOnce
  storageClassName: nonexistent-class
  resources:
    requests:
      storage: 500Mi
YAML

echo "storage-learn ready (no StorageClass/PV/PVC of this lab, no default class); broken-pvc seeded Pending for step 8"
