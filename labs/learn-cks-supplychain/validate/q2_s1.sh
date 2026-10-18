#!/bin/bash
NS=cks-supply
JOB=kubesec-scan
J=$(kubectl -n "$NS" get job "$JOB" -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ Job '$JOB' not found in $NS. Create a Job running kubesec/kubesec:latest with args 'scan /manifests/pod.yaml', mounting kubesec-manifest at /manifests."; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
d=json.loads(os.environ['J'])
def fail(m): print("❌ "+m); sys.exit(1)
suc=(d.get("status") or {}).get("succeeded") or 0
if suc<1: fail("Job kubesec-scan has not completed (succeeded=%s). Wait: kubectl -n cks-supply wait --for=condition=complete job/kubesec-scan --timeout=180s"%suc)
print("ok")
PY
[ $? -ne 0 ] && exit 1
LOGS=$(kubectl -n "$NS" logs job/"$JOB" 2>/dev/null)
echo "$LOGS" | grep -Eiq '"score"|score' || { echo "❌ Job kubesec-scan logs contain no kubesec report (no 'score'). Ensure args are 'scan /manifests/pod.yaml' and the ConfigMap is mounted at /manifests."; exit 1; }
echo "✅ kubesec-scan completed and produced a score/report"
exit 0
