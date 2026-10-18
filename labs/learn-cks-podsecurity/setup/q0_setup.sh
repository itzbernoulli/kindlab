#!/bin/bash
# Prepare cks-podsec: resource-level cleanup of the pods this lab builds (NO ns delete).
# Also ensure cks-locked exists WITHOUT any PSA label (steps add it). Idempotent.
NS=cks-podsec
kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create namespace "$NS" >/dev/null 2>&1
kubectl -n "$NS" delete pod secure-app cap-app ro-app seccomp-app noesc-app restricted-app broken-app \
  --ignore-not-found --force --grace-period=0 >/dev/null 2>&1

# cks-locked starts WITHOUT any enforce/audit label (steps 7 adds them).
kubectl get ns cks-locked >/dev/null 2>&1 || kubectl create namespace cks-locked >/dev/null 2>&1
kubectl label ns cks-locked \
  pod-security.kubernetes.io/enforce- pod-security.kubernetes.io/enforce-version- \
  pod-security.kubernetes.io/audit- pod-security.kubernetes.io/audit-version- \
  pod-security.kubernetes.io/warn- pod-security.kubernetes.io/warn-version- \
  --overwrite >/dev/null 2>&1

echo "cks-podsec ready (pods cleaned); cks-locked created with no PSA labels"
