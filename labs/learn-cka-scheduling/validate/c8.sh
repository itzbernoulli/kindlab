#!/bin/bash
# sched-diag Deployment must have >=1 available replica (scheduling fault fixed); don't delete it.
if ! kubectl -n sched-learn get deploy sched-diag >/dev/null 2>&1; then
  echo "❌ Deployment 'sched-diag' not found (don't delete it — diagnose and fix it)"; exit 1
fi
A=$(kubectl -n sched-learn get deploy sched-diag -o jsonpath='{.status.availableReplicas}' 2>/dev/null)
if [ "${A:-0}" -ge 1 ] 2>/dev/null; then
  echo "✅ Deployment sched-diag has ${A} available replica(s) — scheduling fault fixed"; exit 0
fi
echo "❌ Deployment sched-diag has 0 available replicas — its pod is still Pending (check 'kubectl describe pod -l app=sched-diag' events: no node matches its nodeSelector)"; exit 1
