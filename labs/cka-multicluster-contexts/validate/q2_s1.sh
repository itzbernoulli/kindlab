#!/bin/bash
J=$(kubectl --context "$CTX2" -n prod get deploy api -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ Deployment 'api' not found in prod on cluster2 ($CTX2): kubectl --context $CTX2 -n prod create deployment api --image=nginx:alpine --replicas=2"; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
d=json.loads(os.environ['J'])["spec"]
def fail(m): print("❌ "+m); sys.exit(1)
r=d.get("replicas")
if r!=2: fail("Deployment 'api' must have 2 replicas (got %r)"%r)
imgs=[c.get("image") for c in d["template"]["spec"]["containers"]]
if "nginx:alpine" not in imgs: fail("Deployment 'api' container image must be nginx:alpine (got %s)"%imgs)
print("✅ Deployment 'api' (nginx:alpine, 2 replicas) in prod on cluster2")
PY
