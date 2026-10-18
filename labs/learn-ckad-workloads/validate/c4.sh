#!/bin/bash
J=$(kubectl -n workloads-learn get job bounded -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ Job 'bounded' not found"; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
s=json.loads(os.environ['J'])["spec"]
def fail(m): print("❌ "+m); sys.exit(1)
if s.get("activeDeadlineSeconds")!=300: fail("activeDeadlineSeconds must be 300 (got %r)"%s.get("activeDeadlineSeconds"))
if s.get("ttlSecondsAfterFinished")!=30: fail("ttlSecondsAfterFinished must be 30 (got %r)"%s.get("ttlSecondsAfterFinished"))
print("✅ Job bounded: activeDeadlineSeconds 300, ttlSecondsAfterFinished 30")
PY
