#!/bin/bash
# Reset the learn-cks-falco environment to a clean slate (idempotent, non-destructive to the cluster).
# Removes any Falco install and trigger pods so the student starts from scratch.
helm uninstall falco -n falco >/dev/null 2>&1
kubectl delete namespace falco --ignore-not-found --wait=false >/dev/null 2>&1
kubectl delete pod trip --ignore-not-found >/dev/null 2>&1
# wait briefly for the namespace to terminate so a fresh install succeeds
for i in $(seq 1 20); do kubectl get ns falco >/dev/null 2>&1 || break; sleep 1; done
echo "learn-cks-falco reset: namespace 'falco' and trigger pod removed"
