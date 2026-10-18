#!/bin/bash
# Reset the learn-cka-clusterops lab to a clean, idempotent slate.

# Step 1: remove any static-web manifest + mirror pod on the worker.
docker exec "$W1" rm -f /etc/kubernetes/manifests/static-web.yaml >/dev/null 2>&1
kubectl delete pod "static-web-$W1" -n default --ignore-not-found --wait=false >/dev/null 2>&1

# Step 2: ensure kube-scheduler manifest has no leftover bogus flag.
docker exec "$CP" sed -i '/--bogus-flag=true/d' /etc/kubernetes/manifests/kube-scheduler.yaml >/dev/null 2>&1

# Step 3: remove any previous etcd snapshot.
docker exec "$CP" rm -f /opt/snapshot.db /var/lib/etcd/snapshot.db >/dev/null 2>&1

# Step 4/5: make sure W2 is schedulable (clean slate for cordon/drain/uncordon).
kubectl uncordon "$W2" >/dev/null 2>&1

echo "learn-cka-clusterops reset: static pod cleared, scheduler clean, snapshot removed, $W2 uncordoned"
