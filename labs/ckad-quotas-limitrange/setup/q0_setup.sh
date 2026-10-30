#!/bin/bash
# Resource-level cleanup (NEVER delete the namespace — that races under load).
# Ensure the ns exists, remove the objects this lab builds, then seed the broken
# Deployment 'shipit' for the step-8 diagnose-and-fix.
NS=ckad-quotas
kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create namespace "$NS" >/dev/null 2>&1

# Remove learner-built + seeded objects so re-runs start clean.
kubectl -n "$NS" delete pod fits nodefaults --ignore-not-found --force --grace-period=0 >/dev/null 2>&1
kubectl -n "$NS" delete deployment shipit --ignore-not-found >/dev/null 2>&1
kubectl -n "$NS" delete resourcequota compute-quota object-quota be-quota seed-quota --ignore-not-found >/dev/null 2>&1
kubectl -n "$NS" delete limitrange defaults constraints ratios --ignore-not-found >/dev/null 2>&1

# Seed a compute ResourceQuota so the step-8 Deployment is rejected from the start,
# independent of whether the learner has done step 1 yet. (The learner's own
# 'compute-quota' in step 1 is separate and graded separately.)
kubectl -n "$NS" apply -f - >/dev/null 2>&1 <<'YAML'
apiVersion: v1
kind: ResourceQuota
metadata: { name: seed-quota, namespace: ckad-quotas }
spec:
  hard:
    requests.cpu: "2"
    requests.memory: 2Gi
    limits.cpu: "4"
    limits.memory: 4Gi
YAML

# Broken on purpose: the container declares NO resources, so the compute quota
# refuses every pod -> the Deployment is stuck at 0/1 until the learner adds a
# full resources block to the pod template (step 8 diagnose & fix).
kubectl -n "$NS" apply -f - >/dev/null 2>&1 <<'YAML'
apiVersion: apps/v1
kind: Deployment
metadata: { name: shipit, namespace: ckad-quotas, labels: { app: shipit } }
spec:
  replicas: 1
  selector: { matchLabels: { app: shipit } }
  template:
    metadata: { labels: { app: shipit } }
    spec:
      containers:
      - name: web
        image: nginx:1.25
YAML
echo "ckad-quotas ready; compute 'seed-quota' + broken Deployment 'shipit' seeded (rejected by quota, 0/1 — diagnose & fix in step 8)"
