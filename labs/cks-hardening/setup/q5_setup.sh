#!/bin/bash
# Seed an un-labeled namespace restricted-ns. Candidate adds the PSA enforce labels.
kubectl create namespace restricted-ns --dry-run=client -o yaml | kubectl apply -f - >/dev/null 2>&1
# Remove any PSA enforce labels so grading reflects the candidate's work.
kubectl label ns restricted-ns \
  pod-security.kubernetes.io/enforce- \
  pod-security.kubernetes.io/enforce-version- >/dev/null 2>&1 || true
echo "seeded namespace restricted-ns (no Pod Security Admission labels yet)"
