#!/bin/bash
# Ensure the cks-learn namespace and the 'reader' ServiceAccount exist for the RBAC task.
# Clean up any Role/RoleBinding from a previous attempt so the step starts fresh.
kubectl get namespace cks-learn >/dev/null 2>&1 || kubectl create namespace cks-learn >/dev/null 2>&1
kubectl -n cks-learn get serviceaccount reader >/dev/null 2>&1 || kubectl -n cks-learn create serviceaccount reader >/dev/null 2>&1
kubectl -n cks-learn delete role pod-reader --ignore-not-found >/dev/null 2>&1
kubectl -n cks-learn delete rolebinding reader-pr --ignore-not-found >/dev/null 2>&1
echo "cks-learn ready with ServiceAccount 'reader' (grant it least-privilege pod read access)"
