#!/bin/bash
J=$(kubectl -n shop get deploy checkout -o json 2>/dev/null)
[ -z "$J" ] && { echo "❌ Deployment 'checkout' not found in namespace shop"; exit 1; }
export J
python3 - <<'PY'
import os,json
d=json.loads(os.environ['J'])
sp=d["spec"]; ps=sp["template"]["spec"]; cs=ps.get("containers",[]) or [{}]; cont=cs[0]
if sp.get("replicas")!=3: print("❌ replicas is %r, expected 3"%sp.get("replicas")); raise SystemExit(1)
if len(ps.get("containers",[]))!=1: print("❌ expected exactly 1 container, found %d"%len(ps.get("containers",[]))); raise SystemExit(1)
if cont.get("name")!="api": print("❌ container name is %r, expected 'api'"%cont.get("name")); raise SystemExit(1)
if cont.get("image")!="nginx:1.27-alpine": print("❌ image is %r, expected 'nginx:1.27-alpine'"%cont.get("image")); raise SystemExit(1)
print("✅ checkout: 3 replicas, one container 'api' on nginx:1.27-alpine")
PY
