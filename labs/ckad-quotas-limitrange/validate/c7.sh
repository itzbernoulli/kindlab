#!/bin/bash
J=$(kubectl -n ckad-quotas get limitrange ratios -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ LimitRange 'ratios' not found in ckad-quotas"; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
def fail(m): print("❌ "+m); sys.exit(1)
lr=json.loads(os.environ['J'])["spec"]["limits"]
c=next((x for x in lr if x.get("type")=="Container"),None)
if not c: fail("LimitRange 'ratios' needs a type: Container entry")
r=c.get("maxLimitRequestRatio") or {}
if str(r.get("cpu"))!="4": fail("maxLimitRequestRatio.cpu=%r, want '4'"%r.get("cpu"))
print("✅ ratios: maxLimitRequestRatio.cpu == 4")
PY
