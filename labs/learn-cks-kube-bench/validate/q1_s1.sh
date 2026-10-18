#!/bin/bash
# The Job must have completed, and its pod logs must contain real CIS findings.
NS=cks-bench
SUCC=$(kubectl -n "$NS" get job kube-bench -o jsonpath='{.status.succeeded}' 2>/dev/null)
if [ "${SUCC:-0}" -lt 1 ] 2>/dev/null; then
  echo "❌ Job 'kube-bench' in $NS has not completed (succeeded='${SUCC:-0}'). Create it (aquasec/kube-bench, hostPID, host mounts) and wait for it to finish."; exit 1
fi
LOGS=$(kubectl -n "$NS" logs job/kube-bench 2>/dev/null)
if echo "$LOGS" | grep -Eq '\[(PASS|FAIL|WARN)\]'; then
  N=$(echo "$LOGS" | grep -Ec '\[(PASS|FAIL|WARN)\]')
  echo "✅ Job kube-bench completed with $N CIS findings ([PASS]/[FAIL]/[WARN]) in its logs"; exit 0
fi
echo "❌ Job kube-bench completed but no CIS findings in its logs. Ensure it runs 'kube-bench run --targets node' with the host filesystem mounted."; exit 1
