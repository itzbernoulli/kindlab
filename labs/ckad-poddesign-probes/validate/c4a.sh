#!/bin/bash
J=$(kubectl -n pod-design get pod health-pod -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ pod 'health-pod' not found in pod-design"; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
c=json.loads(os.environ['J'])["spec"]["containers"][0]
def fail(m): print("❌ "+m); sys.exit(1)
lp=c.get("livenessProbe") or {}
if "exec" not in lp: fail("livenessProbe must use the exec handler")
if lp.get("periodSeconds")!=15: fail("livenessProbe.periodSeconds must be 15 (got %r)"%lp.get("periodSeconds"))
print("✅ livenessProbe: exec, periodSeconds 15")
PY
