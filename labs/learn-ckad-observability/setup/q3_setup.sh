#!/bin/bash
# Re-seed step 3: a pod requesting an impossible amount of CPU (stays Pending).
NS=ckad-observability
kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create namespace "$NS" >/dev/null 2>&1
kubectl delete pod bigask -n "$NS" --ignore-not-found --force --grace-period=0 >/dev/null 2>&1
kubectl run bigask -n "$NS" --image=busybox:1.36 \
  --overrides='{"spec":{"containers":[{"name":"bigask","image":"busybox:1.36","command":["sleep","3600"],"resources":{"requests":{"cpu":"9999"}}}]}}' \
  >/dev/null 2>&1
echo "seeded pod 'bigask' with an unschedulable CPU request (Pending) in $NS"
