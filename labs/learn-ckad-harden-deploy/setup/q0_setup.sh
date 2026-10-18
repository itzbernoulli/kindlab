#!/bin/bash
# Seed ONLY the dependencies the candidate must wire in. They build the Deployment + Service.
NS=shop
kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create namespace "$NS" >/dev/null 2>&1
# clean any prior attempt so grading is honest
kubectl -n "$NS" delete deployment checkout --ignore-not-found >/dev/null 2>&1
kubectl -n "$NS" delete service checkout --ignore-not-found >/dev/null 2>&1
# (re)seed dependencies
kubectl -n "$NS" delete configmap checkout-cfg --ignore-not-found >/dev/null 2>&1
kubectl -n "$NS" create configmap checkout-cfg --from-literal=LOG_LEVEL=info --from-literal=REGION=eu >/dev/null 2>&1
kubectl -n "$NS" delete secret checkout-sec --ignore-not-found >/dev/null 2>&1
kubectl -n "$NS" create secret generic checkout-sec --from-literal=API_KEY=s3cr3t >/dev/null 2>&1
kubectl -n "$NS" get sa checkout-sa >/dev/null 2>&1 || kubectl -n "$NS" create serviceaccount checkout-sa >/dev/null 2>&1
echo "shop ready: ConfigMap checkout-cfg, Secret checkout-sec, ServiceAccount checkout-sa. Build the 'checkout' Deployment + Service per the brief."
