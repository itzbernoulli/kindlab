#!/bin/bash
# Seed step 3 (diagnose & fix): break the CNI on $W2 by removing its config file,
# then pin pod 'netbroken' to $W2 so it hangs in ContainerCreating with no IP.
# The learner restores it by bouncing kindnet on $W2.

NS=cni-learn
kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create namespace "$NS" >/dev/null 2>&1

# Remove any previous netbroken pod (idempotent re-seed).
kubectl -n "$NS" delete pod netbroken --ignore-not-found --force --grace-period=0 >/dev/null 2>&1

# Break the CNI on $W2: delete the kindnet conflist so new pods there get no networking.
docker exec "$W2" rm -f /etc/cni/net.d/10-kindnet.conflist >/dev/null 2>&1

# Pin a pod to $W2 — it will sit without an IP until the CNI config is restored.
kubectl run netbroken -n "$NS" --image=busybox:1.36 \
  --overrides="{\"spec\":{\"nodeName\":\"$W2\"}}" \
  --command -- sleep 3600 >/dev/null 2>&1

echo "learn-cka-cni step 3 seeded: CNI config removed on $W2; pod 'netbroken' stuck without an IP"
