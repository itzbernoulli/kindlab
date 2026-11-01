#!/bin/bash
# Prepare helm-learn: uninstall the 'web' release (and clean leftovers).
# Resource-level cleanup only (never delete the namespace).
NS=helm-learn
kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create namespace "$NS" >/dev/null 2>&1
helm uninstall web -n "$NS" >/dev/null 2>&1
# belt-and-suspenders: remove any leftover objects/secret for the release
kubectl -n "$NS" delete deploy,svc,sa -l app.kubernetes.io/instance=web --ignore-not-found >/dev/null 2>&1
kubectl -n "$NS" delete secret -l owner=helm,name=web --ignore-not-found >/dev/null 2>&1
echo "helm-learn ready (release 'web' uninstalled)"
