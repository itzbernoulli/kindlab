#!/bin/bash
if ! kubectl -n ckad-quotas get deploy shipit >/dev/null 2>&1; then echo "❌ Deployment 'shipit' not found (don't delete it — fix its pod template)"; exit 1; fi
A=$(kubectl -n ckad-quotas get deploy shipit -o jsonpath='{.status.availableReplicas}' 2>/dev/null)
if [ "${A:-0}" -ge 1 ] 2>/dev/null; then echo "✅ Deployment shipit has ${A} available replica(s) — quota rejection fixed in the pod template"; exit 0; fi
echo "❌ Deployment shipit has 0 available replicas — its pods are still rejected by the quota (describe the ReplicaSet; add a full resources block to the pod template)"; exit 1
