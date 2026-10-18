#!/bin/bash
# Reset the learn environment to a clean slate (idempotent).
# Remove any pods/daemonsets the learner created, strip test labels/taints, recreate namespace.
kubectl delete namespace sched-learn --ignore-not-found --wait=false >/dev/null 2>&1

# Clean labels/taints this lab adds, on all worker nodes.
for N in "$W1" "$W2"; do
  [ -n "$N" ] || continue
  kubectl label node "$N" disktype- tier- >/dev/null 2>&1
  kubectl taint node "$N" workload=batch:NoSchedule- >/dev/null 2>&1
  kubectl taint node "$N" workload:NoSchedule- >/dev/null 2>&1
done

# Wait for namespace to be fully gone, then recreate.
for i in $(seq 1 30); do kubectl get ns sched-learn >/dev/null 2>&1 || break; sleep 1; done
kubectl create namespace sched-learn >/dev/null 2>&1
echo "sched-learn ready (labels/taints cleared, namespace recreated)"
