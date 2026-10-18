#!/bin/bash
# Prepare learn-cka-scheduling. Resource-level cleanup ONLY (never delete the namespace —
# that races under parallel load and wipes the lab). Ensure the ns exists, delete the exact
# objects this lab builds, reset node labels/taints to a known baseline, and seed the
# broken Deployment 'sched-diag' for the step-8 diagnose-and-fix.
NS=sched-learn
kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create namespace "$NS" >/dev/null 2>&1

# Remove exactly what the learner creates (idempotent; no ns delete).
kubectl -n "$NS" delete pod ssd-pod batch-pod affinity-pod prefer-pod manual-pod \
  --ignore-not-found --force --grace-period=0 >/dev/null 2>&1
kubectl -n "$NS" delete daemonset node-agent --ignore-not-found >/dev/null 2>&1
kubectl -n "$NS" delete deployment spread sched-diag --ignore-not-found >/dev/null 2>&1

# Reset node labels/taints this lab touches, on both workers, to a clean baseline.
for N in "$W1" "$W2"; do
  [ -n "$N" ] || continue
  kubectl uncordon "$N" >/dev/null 2>&1
  kubectl label node "$N" disktype- tier- zone- >/dev/null 2>&1
  kubectl taint node "$N" workload=batch:NoSchedule- >/dev/null 2>&1
  kubectl taint node "$N" workload:NoSchedule- >/dev/null 2>&1
done

# Pre-seed the labels the lesson text says are "already present":
#  - W1 gets tier=gold (step 3 required nodeAffinity target)
#  - W1 gets zone=a, W2 gets zone=b (step 4 preferred nodeAffinity)
[ -n "$W1" ] && kubectl label node "$W1" tier=gold zone=a --overwrite >/dev/null 2>&1
[ -n "$W2" ] && kubectl label node "$W2" zone=b --overwrite >/dev/null 2>&1

# Broken on purpose for the final step: nodeSelector disktype=nvme matches NO node, so the
# pod stays Pending forever. The learner diagnoses the unschedulable cause and fixes it so
# the Deployment reports an available replica. (nginx:1.25 runs fine once it can schedule.)
kubectl -n "$NS" apply -f - >/dev/null 2>&1 <<'YAML'
apiVersion: apps/v1
kind: Deployment
metadata: { name: sched-diag, labels: { app: sched-diag } }
spec:
  replicas: 1
  selector: { matchLabels: { app: sched-diag } }
  template:
    metadata: { labels: { app: sched-diag } }
    spec:
      nodeSelector:
        disktype: nvme
      containers:
      - name: web
        image: nginx:1.25
YAML

echo "sched-learn ready: W1=$W1 (tier=gold, zone=a), W2=$W2 (zone=b); broken Deployment 'sched-diag' seeded (Pending — diagnose & fix in the last step)"
