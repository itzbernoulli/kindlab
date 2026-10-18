#!/bin/bash
# Seed namespace netpol-lab with a couple of running pods and NO NetworkPolicy.
kubectl create namespace netpol-lab --dry-run=client -o yaml | kubectl apply -f - >/dev/null 2>&1
kubectl -n netpol-lab run web --image=busybox:1.36 --restart=Never --command -- sleep 3600 >/dev/null 2>&1 || true
kubectl -n netpol-lab run client --image=busybox:1.36 --restart=Never --command -- sleep 3600 >/dev/null 2>&1 || true
# Remove any pre-existing NetworkPolicy so grading reflects the candidate's work.
kubectl -n netpol-lab delete networkpolicy --all >/dev/null 2>&1 || true
echo "seeded namespace netpol-lab with pods and no NetworkPolicy"
