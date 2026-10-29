#!/bin/bash
# Reset learn-cka-clusterops to a clean, idempotent slate.
# NODE-LEVEL lab: all cleanup is resource-level — NEVER delete the namespace.

# Ensure the default namespace exists (it always does, but be defensive).
kubectl get ns default >/dev/null 2>&1 || kubectl create namespace default >/dev/null 2>&1

# Step 1: remove any leftover static-web manifest + mirror pod on the worker.
docker exec "$W1" rm -f /etc/kubernetes/manifests/static-web.yaml >/dev/null 2>&1
kubectl -n default delete pod "static-web-$W1" --ignore-not-found --wait=false >/dev/null 2>&1

# Step 2/8: ensure no leftover bogus flags in control-plane manifests.
docker exec "$CP" sed -i '/--bogus-flag=true/d' /etc/kubernetes/manifests/kube-scheduler.yaml >/dev/null 2>&1
docker exec "$CP" sed -i '/--bogus-flag=true/d' /etc/kubernetes/manifests/kube-controller-manager.yaml >/dev/null 2>&1

# Step 3: remove any previous etcd snapshot.
docker exec "$CP" rm -f /opt/snapshot.db /var/lib/etcd/snapshot.db >/dev/null 2>&1

# Step 4: clear any leftover taint on W1 so the learner must add it.
kubectl taint nodes "$W1" workload- >/dev/null 2>&1

# Step 5/6: make W2 and CP schedulable (clean slate for cordon/drain + uncordon).
kubectl uncordon "$W2" >/dev/null 2>&1
kubectl uncordon "$CP" >/dev/null 2>&1

# Step 7: clear any leftover disk label on W2.
kubectl label node "$W2" disk- >/dev/null 2>&1

echo "learn-cka-clusterops reset: static pod cleared, control-plane manifests clean, snapshot removed, $W1 untainted, $W2/$CP uncordoned, $W2 unlabeled"
