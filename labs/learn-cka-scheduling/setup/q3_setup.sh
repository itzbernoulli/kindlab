#!/bin/bash
# Step 3 start: pre-label $W1 with tier=gold (the lesson says it is already labeled).
# Remove the step-2 taint so a plain affinity pod (which also tolerates everything in the
# solution) isn't the only option, and clear any leftover pod.
kubectl create namespace sched-learn >/dev/null 2>&1
kubectl label node "$W1" tier=gold --overwrite >/dev/null 2>&1
kubectl taint node "$W1" workload=batch:NoSchedule- >/dev/null 2>&1
kubectl taint node "$W1" workload:NoSchedule- >/dev/null 2>&1
kubectl -n sched-learn delete pod affinity-pod --ignore-not-found --wait=false >/dev/null 2>&1
echo "step 3 ready: node '$W1' labeled tier=gold — create affinity-pod with required nodeAffinity tier In [gold]"
