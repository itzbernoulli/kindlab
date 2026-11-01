#!/bin/bash
# Deployment api now has a CPU request; HPA api still targets it.
D=$(kubectl -n hpa-learn get deploy api -o json 2>/dev/null); [ -z "$D" ] && { echo "❌ Deployment 'api' not found"; exit 1; }
H=$(kubectl -n hpa-learn get hpa api -o json 2>/dev/null); [ -z "$H" ] && { echo "❌ HPA 'api' not found (don't delete it — fix the Deployment's request)"; exit 1; }
export D H
python3 - <<'PY'
import os,json,sys
def fail(m): print("❌ "+m); sys.exit(1)
d=json.loads(os.environ["D"])
c=d["spec"]["template"]["spec"]["containers"][0]
cpu=((c.get("resources") or {}).get("requests") or {}).get("cpu")
if not cpu: fail("Deployment 'api' container still has no CPU request — add resources.requests.cpu (e.g. 100m)")
h=json.loads(os.environ["H"]); ref=h["spec"].get("scaleTargetRef",{})
if ref.get("name")!="api": fail("HPA 'api' no longer targets Deployment api (got %r)"%ref)
print("✅ Deployment api has CPU request %s; HPA api targets it (can now compute utilization)"%cpu)
PY
