#!/bin/bash
J=$(kubectl -n workloads-learn get job retry -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ Job 'retry' not found"; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
s=json.loads(os.environ['J'])["spec"]
def fail(m): print("❌ "+m); sys.exit(1)
if s.get("backoffLimit")!=4: fail("backoffLimit must be 4 (got %r)"%s.get("backoffLimit"))
if s["template"]["spec"].get("restartPolicy")!="OnFailure": fail("restartPolicy must be OnFailure")
print("✅ Job retry: backoffLimit 4, restartPolicy OnFailure")
PY
