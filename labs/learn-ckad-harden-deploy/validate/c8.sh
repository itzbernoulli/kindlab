#!/bin/bash
J=$(kubectl -n shop get deploy checkout -o json 2>/dev/null)
[ -z "$J" ] && { echo "❌ Deployment 'checkout' not found in namespace shop"; exit 1; }
export J
python3 - <<'PY'
import os,json
d=json.loads(os.environ['J'])
sp=d["spec"]; ps=sp["template"]["spec"]; cs=ps.get("containers",[]) or [{}]; cont=cs[0]
r=cont.get("resources") or {}; req=r.get("requests") or {}; lim=r.get("limits") or {}
if req.get("cpu")!="100m" or req.get("memory")!="128Mi": print("❌ requests must be cpu=100m memory=128Mi (got %r)"%req); raise SystemExit(1)
if lim.get("cpu")!="250m" or lim.get("memory")!="256Mi": print("❌ limits must be cpu=250m memory=256Mi (got %r)"%lim); raise SystemExit(1)
print("✅ resources requests 100m/128Mi + limits 250m/256Mi")
PY
