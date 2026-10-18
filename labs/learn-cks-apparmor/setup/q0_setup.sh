#!/bin/bash
# Reset the AppArmor learn environment to a clean slate (idempotent).
# Resource-level cleanup only — NEVER delete the namespace (races under load).
NS=cks-apparmor
kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create namespace "$NS" >/dev/null 2>&1

# Remove the pods/ConfigMap this lab builds so each run starts fresh.
kubectl -n "$NS" delete pod confined unconfined rtdefault netlocked broken-aa \
  --ignore-not-found --force --grace-period=0 >/dev/null 2>&1
kubectl -n "$NS" delete configmap apparmor-proof --ignore-not-found >/dev/null 2>&1

# Unload + remove the profile files the learner creates, so Steps 1/6/8 start fresh.
# (apparmor_parser -R is best-effort; the node may not have AppArmor on this host.)
for P in k8s-deny-write k8s-deny-net k8s-audit-write; do
  docker exec "$W1" sh -c "apparmor_parser -R /etc/apparmor.d/$P >/dev/null 2>&1; rm -f /etc/apparmor.d/$P" >/dev/null 2>&1
done

# Seed the Step 8 diagnose-and-fix: a pod pinned to $W1 that references a Localhost
# profile 'k8s-audit-write' which is NOT written or loaded on the node. On an AppArmor
# host it cannot start until the learner writes + loads that profile.
kubectl -n "$NS" apply -f - >/dev/null 2>&1 <<YAML
apiVersion: v1
kind: Pod
metadata:
  name: broken-aa
  namespace: $NS
spec:
  nodeName: $W1
  containers:
  - name: hello
    image: busybox:1.36
    command: ["sleep","3600"]
    securityContext:
      appArmorProfile:
        type: Localhost
        localhostProfile: k8s-audit-write
YAML

echo "cks-apparmor ready (ns present; stale profiles removed on $W1; broken-aa seeded for Step 8)"
