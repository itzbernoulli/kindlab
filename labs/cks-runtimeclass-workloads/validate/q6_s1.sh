#!/bin/bash
J=$(kubectl -n runtimeclass-learn get deployment sandboxed-web -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ Deployment 'sandboxed-web' not found in runtimeclass-learn."; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
sp=json.loads(os.environ['J'])["spec"]
def fail(m): print("❌ "+m); sys.exit(1)
if sp.get("replicas")!=2: fail("spec.replicas must be 2 (got %r)"%sp.get("replicas"))
tsp=(sp.get("template") or {}).get("spec") or {}
rc=tsp.get("runtimeClassName")
if rc!="gvisor": fail("spec.template.spec.runtimeClassName must be 'gvisor' (got %r). It belongs in the POD TEMPLATE, not deployment.spec."%rc)
imgs=[c.get("image") for c in tsp.get("containers",[])]
if "nginx:1.25" not in imgs: fail("template container image must be nginx:1.25 (got %r)"%imgs)
print("✅ Deployment 'sandboxed-web': 2 replicas + template.spec.runtimeClassName gvisor")
PY
