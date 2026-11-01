#!/bin/bash
# Prepare crd-learn. Remove the cluster-scoped Widget CRD (this deletes all its
# custom resources too). Resource-level cleanup only (never delete the namespace).
NS=crd-learn
kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create namespace "$NS" >/dev/null 2>&1
kubectl delete crd widgets.example.com --ignore-not-found >/dev/null 2>&1
echo "crd-learn ready (Widget CRD removed)"
