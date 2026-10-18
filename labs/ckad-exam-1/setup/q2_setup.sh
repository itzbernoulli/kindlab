#!/bin/bash
# Seed the 'roller' deployment at the OLD image so the learner can roll it forward.
kubectl -n exam delete deployment roller --ignore-not-found >/dev/null 2>&1
kubectl -n exam create deployment roller --image=nginx:1.24 --replicas=3 >/dev/null 2>&1
echo "seeded deployment 'roller' at nginx:1.24 in namespace exam"
