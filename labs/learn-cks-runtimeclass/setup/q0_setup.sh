#!/bin/bash
# Reset the learn environment to a clean slate (idempotent).
kubectl delete namespace runtimeclass-learn --ignore-not-found --wait=true >/dev/null 2>&1
kubectl delete runtimeclass gvisor --ignore-not-found >/dev/null 2>&1
kubectl delete runtimeclass kata   --ignore-not-found >/dev/null 2>&1
kubectl create namespace runtimeclass-learn >/dev/null 2>&1
echo "runtimeclass-learn ready (namespace created; no RuntimeClasses — you create them)"
