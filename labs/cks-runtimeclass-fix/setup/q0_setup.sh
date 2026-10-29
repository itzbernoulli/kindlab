#!/bin/bash
# Prepare runtimeclass-learn: resource-level cleanup (NO namespace delete — that races
# under load). Ensure the ns exists, remove the objects this lab builds, then seed a
# BROKEN pod ('brokenrc' references a non-existent RuntimeClass) for the diagnose-and-fix.
NS=runtimeclass-learn
kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create namespace "$NS" >/dev/null 2>&1

# Pods this lab builds / seeds
kubectl -n "$NS" delete pod sandboxed normal brokenrc \
  --ignore-not-found --force --grace-period=0 >/dev/null 2>&1
kubectl -n "$NS" delete deployment sandboxed-web --ignore-not-found >/dev/null 2>&1

# Cluster-scoped RuntimeClasses the learner creates (clean so handler checks are honest)
kubectl delete runtimeclass gvisor kata --ignore-not-found >/dev/null 2>&1

# Broken on purpose: references RuntimeClass 'gvisro' (a typo) which does not exist, so the
# pod is rejected/stuck with reason RuntimeClassName not found. Learner fixes it to 'gvisor'.
kubectl -n "$NS" apply -f - >/dev/null 2>&1 <<'YAML'
apiVersion: v1
kind: Pod
metadata:
  name: brokenrc
  namespace: runtimeclass-learn
spec:
  runtimeClassName: gvisro
  containers:
  - name: c
    image: busybox:1.36
    command: ["sleep","3600"]
YAML

# PREREQUISITE (severed-chain reseed): the RuntimeClasses gvisor + kata are built
# in an earlier exercise now living in cks-runtimeclass-create. Seed them so this
# lab's pods/deployments can reference them and stand alone.
kubectl apply -f - >/dev/null 2>&1 <<'YAML'
apiVersion: node.k8s.io/v1
kind: RuntimeClass
metadata:
  name: gvisor
handler: runsc
---
apiVersion: node.k8s.io/v1
kind: RuntimeClass
metadata:
  name: kata
handler: kata
scheduling:
  nodeSelector:
    runtime: kata
overhead:
  podFixed:
    memory: 64Mi
    cpu: 50m
YAML

echo "runtimeclass-learn ready; no RuntimeClasses (you create them); broken pod 'brokenrc' seeded (bad runtimeClassName — diagnose & fix in the last step)"
