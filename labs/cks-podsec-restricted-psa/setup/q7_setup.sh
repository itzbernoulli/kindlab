#!/bin/bash
# Ensure cks-locked exists WITHOUT any PSA enforce/audit label, so the learner must add them. Idempotent.
kubectl get ns cks-locked >/dev/null 2>&1 || kubectl create namespace cks-locked >/dev/null 2>&1
kubectl label ns cks-locked \
  pod-security.kubernetes.io/enforce- pod-security.kubernetes.io/enforce-version- \
  pod-security.kubernetes.io/audit- pod-security.kubernetes.io/audit-version- \
  --overwrite >/dev/null 2>&1
echo "namespace cks-locked ready (no PSA labels)"
