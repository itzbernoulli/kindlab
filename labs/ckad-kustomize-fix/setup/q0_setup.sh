#!/bin/bash
# Reset the Helm side to a clean slate WITHOUT deleting the namespace
# (ns delete races under load and wipes the lab). Ensure helm-learn exists,
# uninstall any 'demo' release, clear release Secrets, and clear host scratch
# dirs so nothing passes on an untouched cluster.
NS=helm-learn

kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create namespace "$NS" >/dev/null 2>&1

# Uninstall the release (removes chart objects + release Secrets if present).
helm uninstall demo -n "$NS" >/dev/null 2>&1

# Belt-and-suspenders: resource-level cleanup of anything a prior attempt left.
kubectl -n "$NS" delete deployment demo-webapp --ignore-not-found >/dev/null 2>&1
kubectl -n "$NS" delete secret -l owner=helm,name=demo --ignore-not-found >/dev/null 2>&1

# Clear host scratch used by the learner (chart + rendered output + override file).
rm -rf /tmp/webapp /tmp/rendered.yaml /tmp/override.yaml 2>/dev/null

echo "helm-learn ready (namespace present, no 'demo' release); scaffold + install in step 1"
