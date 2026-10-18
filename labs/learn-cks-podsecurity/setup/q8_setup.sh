#!/bin/bash
# Seed a BROKEN pod for the step-8 diagnose-and-fix: it sets runAsNonRoot:true but NO runAsUser,
# so the root busybox image is rejected by the kubelet and never becomes Ready. Resource-level only.
NS=cks-podsec
kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create namespace "$NS" >/dev/null 2>&1
kubectl -n "$NS" delete pod broken-app --ignore-not-found --force --grace-period=0 >/dev/null 2>&1
kubectl -n "$NS" apply -f - >/dev/null 2>&1 <<'YAML'
apiVersion: v1
kind: Pod
metadata: { name: broken-app, namespace: cks-podsec }
spec:
  containers:
  - name: app
    image: busybox:1.36
    command: ["sleep","3600"]
    securityContext:
      runAsNonRoot: true
YAML
echo "cks-podsec: broken-app seeded (runAsNonRoot with no runAsUser -> won't start; diagnose & fix in step 8)"
