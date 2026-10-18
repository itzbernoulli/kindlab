#!/bin/bash
# Step 1 start: ensure namespace exists and $W1 has NO disktype label yet,
# so the learner must add it. Remove any leftover pod from a prior attempt.
kubectl create namespace sched-learn >/dev/null 2>&1
kubectl -n sched-learn delete pod ssd-pod --ignore-not-found --wait=false >/dev/null 2>&1
kubectl label node "$W1" disktype- >/dev/null 2>&1
echo "step 1 ready: label node '$W1' with disktype=ssd, then create ssd-pod using nodeSelector"
