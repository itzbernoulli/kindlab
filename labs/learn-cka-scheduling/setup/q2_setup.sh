#!/bin/bash
# Step 2 start: keep the disktype=ssd label on $W1 (so the pod can target it),
# but ensure $W1 is NOT yet tainted — the learner adds the taint.
kubectl create namespace sched-learn >/dev/null 2>&1
kubectl label node "$W1" disktype=ssd --overwrite >/dev/null 2>&1
kubectl taint node "$W1" workload=batch:NoSchedule- >/dev/null 2>&1
kubectl taint node "$W1" workload:NoSchedule- >/dev/null 2>&1
kubectl -n sched-learn delete pod batch-pod --ignore-not-found --wait=false >/dev/null 2>&1
echo "step 2 ready: taint '$W1' workload=batch:NoSchedule, then create batch-pod that tolerates it and targets '$W1'"
