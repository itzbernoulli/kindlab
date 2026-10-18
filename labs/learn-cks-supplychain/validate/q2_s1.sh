#!/bin/bash
NS=cks-supply
J=kubesec-scan
kubectl -n "$NS" get job "$J" >/dev/null 2>&1 || { echo "❌ Job $J not found in $NS. Create a Job running controlplaneio/kubesec:latest with args 'scan /manifests/pod.yaml'."; exit 1; }
SUC=$(kubectl -n "$NS" get job "$J" -o jsonpath='{.status.succeeded}' 2>/dev/null)
[ "${SUC:-0}" -ge 1 ] 2>/dev/null || { echo "❌ Job $J has not completed (succeeded='${SUC:-0}'). Wait: kubectl -n $NS wait --for=condition=complete job/$J --timeout=180s"; exit 1; }
LOGS=$(kubectl -n "$NS" logs job/"$J" 2>/dev/null)
echo "$LOGS" | grep -Eiq '"score"|score' || { echo "❌ Job $J logs do not contain a kubesec report (no 'score'). Check the ConfigMap is mounted at /manifests and args are 'scan /manifests/pod.yaml'."; exit 1; }
echo "✅ kubesec-scan completed and produced a score/report"
exit 0
