#!/bin/bash
# Setup for step 3 (Fix the CNI): guarantee a restorable backup exists, then
# DELETE the kindnet DaemonSet so the learner has to restore it.
# q0_setup.sh is always able to bring kindnet back from $LAB_DIR/kindnet.yaml.

LAB_DIR="${LAB_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
BACKUP="$LAB_DIR/kindnet.yaml"

# 1) Make sure we have a good kindnet backup BEFORE deleting it.
if [ ! -s "$BACKUP" ]; then
  if kubectl -n kube-system get ds kindnet >/dev/null 2>&1; then
    kubectl -n kube-system get ds kindnet -o yaml 2>/dev/null \
      | sed -e '/^status:/,$d' > "$BACKUP" 2>/dev/null
  fi
fi

# 2) Seed the broken pod the learner will see recover (no IP while CNI is down).
kubectl delete pod netbroken -n default --ignore-not-found --wait=false >/dev/null 2>&1

# 3) Delete kindnet so new pods cannot get networking (the problem to fix).
kubectl -n kube-system delete ds kindnet --ignore-not-found >/dev/null 2>&1

# 4) Create the stuck test pod (will sit in ContainerCreating until kindnet returns).
kubectl run netbroken --image=busybox:1.36 --restart=Never --command -- sleep 3600 >/dev/null 2>&1

echo "learn-cka-cni step 3 seeded: kindnet deleted, pod 'netbroken' stuck ContainerCreating (restore kindnet from $BACKUP)"
