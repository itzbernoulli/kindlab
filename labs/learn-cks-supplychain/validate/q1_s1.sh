#!/bin/bash
NS=cks-supply
J=trivy-scan
kubectl -n "$NS" get job "$J" >/dev/null 2>&1 || { echo "❌ Job $J not found in $NS. Create a Job running aquasec/trivy:latest with args 'image busybox:1.36'."; exit 1; }
SUC=$(kubectl -n "$NS" get job "$J" -o jsonpath='{.status.succeeded}' 2>/dev/null)
[ "${SUC:-0}" -ge 1 ] 2>/dev/null || { echo "❌ Job $J has not completed (succeeded='${SUC:-0}'). Wait: kubectl -n $NS wait --for=condition=complete job/$J --timeout=180s"; exit 1; }
LOGS=$(kubectl -n "$NS" logs job/"$J" 2>/dev/null)
echo "$LOGS" | grep -Eiq 'Total:|Vulnerabilit' || { echo "❌ Job $J logs do not contain Trivy CVE output (no 'Total:' / 'Vulnerabilities'). Ensure args are 'image busybox:1.36'."; exit 1; }
echo "✅ trivy-scan completed and produced Trivy CVE output"
exit 0
