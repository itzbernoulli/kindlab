#!/bin/bash
# Multi-cluster lab reset — RESOURCE-LEVEL cleanup only (we never remove whole
# namespaces here, since that races under load). Seed the step-7 stray Deployment
# on the WRONG cluster.
# Contexts: $CTX = kind-kindlab (cluster1), $CTX2 = kind-kindlab2 (cluster2).

# --- cluster2: remove anything a prior run left in prod, but keep the ns alone.
# (We do NOT create 'prod' here — step 1 must create it. If it exists from a prior
#  run, clear its contents so steps 1/2/4/7 start clean.)
if kubectl --context "$CTX2" get ns prod >/dev/null 2>&1; then
  kubectl --context "$CTX2" -n prod delete deployment api cache --ignore-not-found >/dev/null 2>&1
  kubectl --context "$CTX2" -n prod delete configmap shared-cfg --ignore-not-found >/dev/null 2>&1
fi
# --- cluster1: remove the resources the lab builds in default, then seed the stray
# 'cache' Deployment in default (the step-7 fault). The learner never puts 'prod' on
# cluster1, so no whole-namespace removal is needed (and it would race under load).
kubectl --context "$CTX" -n default delete configmap shared-cfg --ignore-not-found >/dev/null 2>&1
kubectl --context "$CTX" -n default delete secret db-cred --ignore-not-found >/dev/null 2>&1
kubectl --context "$CTX" -n default delete deployment cache --ignore-not-found >/dev/null 2>&1

# Seed the stray: 'cache' lands in DEFAULT on cluster1 (wrong place) for the step-7 fix.
kubectl --context "$CTX" -n default apply -f - >/dev/null 2>&1 <<'YAML'
apiVersion: apps/v1
kind: Deployment
metadata: { name: cache, namespace: default, labels: { app: cache } }
spec:
  replicas: 1
  selector: { matchLabels: { app: cache } }
  template:
    metadata: { labels: { app: cache } }
    spec:
      containers:
      - name: redis
        image: redis:7
YAML

# Reset cluster2 context's default namespace so step 5 is a real action.
kubectl config set-context "$CTX2" --namespace="" >/dev/null 2>&1

# Leave the active context on cluster1 (where step 3/6/8 and the shell start).
kubectl config use-context "$CTX" >/dev/null 2>&1
echo "multi-cluster lab ready (contexts: $CTX, $CTX2); stray 'cache' seeded in default on cluster1 for step 7"
