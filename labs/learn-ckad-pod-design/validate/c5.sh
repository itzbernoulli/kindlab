#!/bin/bash
J=$(kubectl -n pod-design get pod graceful-pod -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ pod 'graceful-pod' not found in pod-design"; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
ps=json.loads(os.environ['J'])["spec"]; c=ps["containers"][0]; lc=c.get("lifecycle") or {}
def fail(m): print("❌ "+m); sys.exit(1)
if "exec" not in (lc.get("postStart") or {}): fail("lifecycle.postStart must use an exec hook")
if "exec" not in (lc.get("preStop") or {}): fail("lifecycle.preStop must use an exec hook")
if ps.get("terminationGracePeriodSeconds")!=30: fail("terminationGracePeriodSeconds must be 30 (got %r)"%ps.get("terminationGracePeriodSeconds"))
print("✅ graceful-pod: postStart + preStop exec hooks + terminationGracePeriodSeconds 30")
PY
