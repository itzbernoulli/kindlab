#!/bin/bash
NS=cks-supply
JOB=trivy-scan
J=$(kubectl -n "$NS" get job "$JOB" -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ Job '$JOB' not found in $NS. Create a Job running aquasec/trivy:latest with args 'image --severity HIGH,CRITICAL python:3.9.0'."; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
d=json.loads(os.environ['J'])
def fail(m): print("❌ "+m); sys.exit(1)
suc=(d.get("status") or {}).get("succeeded") or 0
if suc<1: fail("Job trivy-scan has not completed (succeeded=%s). Wait: kubectl -n cks-supply wait --for=condition=complete job/trivy-scan --timeout=240s"%suc)
rp=(((d.get("spec") or {}).get("template") or {}).get("spec") or {}).get("restartPolicy")
if rp not in ("Never","OnFailure"): fail("Job pod restartPolicy is %r — must be Never or OnFailure"%rp)
print("ok")
PY
[ $? -ne 0 ] && exit 1
LOGS=$(kubectl -n "$NS" logs job/"$JOB" 2>/dev/null)
echo "$LOGS" | grep -Eiq 'Total:|Vulnerabilit' || { echo "❌ Job trivy-scan logs contain no Trivy CVE output (no 'Total:' / 'Vulnerabilities'). Ensure args are 'image --severity HIGH,CRITICAL python:3.9.0'."; exit 1; }
echo "✅ trivy-scan completed (restartPolicy ok) and produced Trivy CVE output"
exit 0
