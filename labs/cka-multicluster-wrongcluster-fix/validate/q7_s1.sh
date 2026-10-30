#!/bin/bash
# cache must exist in prod on cluster2 (redis:7) AND be gone from default on cluster1.
STRAY=$(kubectl --context "$CTX" -n default get deploy cache -o name 2>/dev/null)
if [ -n "$STRAY" ]; then echo "❌ the stray Deployment 'cache' still exists in default on cluster1 ($CTX) — delete it: kubectl --context $CTX -n default delete deployment cache"; exit 1; fi
J=$(kubectl --context "$CTX2" -n prod get deploy cache -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ Deployment 'cache' not found in prod on cluster2 ($CTX2): kubectl --context $CTX2 -n prod create deployment cache --image=redis:7"; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
d=json.loads(os.environ['J'])["spec"]
def fail(m): print("❌ "+m); sys.exit(1)
imgs=[c.get("image") for c in d["template"]["spec"]["containers"]]
if "redis:7" not in imgs: fail("Deployment 'cache' image must be redis:7 (got %s)"%imgs)
print("✅ Deployment 'cache' (redis:7) in prod on cluster2 and gone from default on cluster1")
PY
