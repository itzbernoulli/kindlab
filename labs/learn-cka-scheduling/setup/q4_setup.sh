#!/bin/bash
# Step 4 start: ensure namespace exists and $W2 is schedulable (uncordon) so a
# nodeName-pinned pod can run there. Clear any leftover pod.
kubectl create namespace sched-learn >/dev/null 2>&1
kubectl uncordon "$W2" >/dev/null 2>&1
kubectl -n sched-learn delete pod manual-pod --ignore-not-found --wait=false >/dev/null 2>&1
echo "step 4 ready: create manual-pod bound to '$W2' via spec.nodeName"
