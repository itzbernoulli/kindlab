#!/bin/bash
# Strict: Job 'kube-bench' must have completed, its pod template must set hostPID:true
# and mount the host (hostPath), and its logs must contain real CIS findings.
NS=cks-bench
J=$(kubectl -n "$NS" get job kube-bench -o json 2>/dev/null)
[ -z "$J" ] && { echo "❌ Job 'kube-bench' not found in $NS. Create it from aquasec/kube-bench with args run --targets node."; exit 1; }
export J
python3 - <<'PY' || exit 1
import os,json,sys
j=json.loads(os.environ['J'])
def fail(m): print("❌ "+m); sys.exit(1)
if (j.get("status") or {}).get("succeeded",0) < 1: fail("Job 'kube-bench' has not completed yet (succeeded<1). Wait for it to finish.")
spec=j["spec"]["template"]["spec"]
if spec.get("hostPID") is not True: fail("pod template must set hostPID: true so kube-bench sees host processes")
vols=spec.get("volumes") or []
hostpaths=[(v.get("hostPath") or {}).get("path") for v in vols if "hostPath" in v]
need="/etc/kubernetes"
if not any(p==need or (p or "").startswith(need) for p in hostpaths):
    fail("pod must hostPath-mount the host filesystem (e.g. /etc/kubernetes); got hostPaths %s"%hostpaths)
print("✅ Job spec OK (hostPID + hostPath mounts)")
PY
LOGS=$(kubectl -n "$NS" logs job/kube-bench 2>/dev/null)
if echo "$LOGS" | grep -Eq '\[(PASS|FAIL|WARN)\]'; then
  N=$(echo "$LOGS" | grep -Ec '\[(PASS|FAIL|WARN)\]')
  echo "✅ Job kube-bench completed with $N CIS findings ([PASS]/[FAIL]/[WARN]) in its logs"; exit 0
fi
echo "❌ Job kube-bench completed but no CIS findings in its logs. Ensure it runs 'kube-bench run --targets node' with the host mounted."; exit 1
