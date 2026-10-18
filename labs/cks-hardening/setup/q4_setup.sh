#!/bin/bash
# Seed namespace rbac-lab with a 'reader' ServiceAccount and a demo pod.
# No RBAC is granted yet — the candidate creates the least-privilege Role + RoleBinding.
kubectl create namespace rbac-lab --dry-run=client -o yaml | kubectl apply -f - >/dev/null 2>&1
kubectl -n rbac-lab create serviceaccount reader --dry-run=client -o yaml | kubectl apply -f - >/dev/null 2>&1
kubectl -n rbac-lab run demo --image=busybox:1.36 --restart=Never --command -- sleep 3600 >/dev/null 2>&1 || true
# Clean up any pre-existing Role/RoleBinding so grading reflects the candidate's work.
kubectl -n rbac-lab delete role,rolebinding --all >/dev/null 2>&1 || true
echo "seeded namespace rbac-lab with ServiceAccount 'reader' (no RBAC yet)"
