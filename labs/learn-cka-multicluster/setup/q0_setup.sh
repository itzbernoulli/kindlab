#!/bin/bash
# Reset on BOTH clusters and leave the active context on cluster1.
kubectl --context "$CTX2" delete namespace prod --ignore-not-found --wait=false >/dev/null 2>&1
kubectl --context "$CTX2" -n default delete configmap shared-cfg --ignore-not-found >/dev/null 2>&1
kubectl --context "$CTX" -n default delete configmap shared-cfg --ignore-not-found >/dev/null 2>&1
kubectl config use-context "$CTX" >/dev/null 2>&1
echo "multi-cluster lesson ready (contexts: $CTX, $CTX2)"
