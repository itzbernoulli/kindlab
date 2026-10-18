#!/bin/bash
# Seed a bare Pod pinned to $W2 so the student has a real workload to evict when draining.
# A bare Pod (not a Deployment) is used deliberately: once drained it stays gone, modelling
# how maintenance eviction clears a node. --force is needed to evict unmanaged pods.
kubectl uncordon "$W2" >/dev/null 2>&1
kubectl delete pod drain-me -n default --ignore-not-found --force --grace-period=0 >/dev/null 2>&1
cat <<YAML | kubectl apply -f - >/dev/null 2>&1
apiVersion: v1
kind: Pod
metadata:
  name: drain-me
  namespace: default
  labels:
    app: drain-me
spec:
  nodeName: $W2
  containers:
  - name: c
    image: busybox:1.36
    command: ["sh","-c","sleep 100000"]
YAML
# Wait for the pod to land on $W2 so the drain actually has something to evict.
for i in $(seq 1 30); do
  P=$(kubectl -n default get pod drain-me -o jsonpath='{.status.phase}' 2>/dev/null)
  [ "$P" = "Running" ] && break
  sleep 1
done
echo "seeded Pod drain-me pinned to $W2"
