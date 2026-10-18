#!/bin/bash
NS=ckad-observability
kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create namespace "$NS" >/dev/null 2>&1
kubectl -n "$NS" delete pod blackbox --ignore-not-found --force --grace-period=0 >/dev/null 2>&1
kubectl -n "$NS" run blackbox --image=busybox:1.36 --command -- sleep 3600 >/dev/null 2>&1
# rename default container to 'app' via a full spec (run names container 'blackbox'); recreate with container app
kubectl -n "$NS" delete pod blackbox --ignore-not-found --force --grace-period=0 >/dev/null 2>&1
kubectl -n "$NS" apply -f - >/dev/null 2>&1 <<'YAML'
apiVersion: v1
kind: Pod
metadata: { name: blackbox, namespace: ckad-observability }
spec:
  containers: [ { name: app, image: busybox:1.36, command: ["sh","-c","sleep 3600"] } ]
YAML
echo "ckad-observability: pod 'blackbox' (container app) seeded for the kubectl debug step"
