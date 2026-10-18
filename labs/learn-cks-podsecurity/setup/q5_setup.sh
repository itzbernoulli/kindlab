#!/bin/bash
# Ensure the target namespace exists WITHOUT a PSA enforce label,
# so the learner must add it. Idempotent.
kubectl get ns cks-locked >/dev/null 2>&1 || kubectl create namespace cks-locked >/dev/null 2>&1
kubectl label ns cks-locked \
  pod-security.kubernetes.io/enforce- \
  pod-security.kubernetes.io/enforce-version- --overwrite >/dev/null 2>&1
echo "namespace cks-locked ready (no PSA enforce label)"
