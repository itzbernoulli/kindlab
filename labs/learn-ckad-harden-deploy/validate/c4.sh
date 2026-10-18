#!/bin/bash
J=$(kubectl -n shop get deploy checkout -o json 2>/dev/null)
[ -z "$J" ] && { echo "❌ Deployment 'checkout' not found in namespace shop"; exit 1; }
export J
python3 - <<'PY'
import os,json
d=json.loads(os.environ['J'])
sp=d["spec"]; ps=sp["template"]["spec"]; cs=ps.get("containers",[]) or [{}]; cont=cs[0]
ef=cont.get("envFrom") or []
if not any((x.get("configMapRef") or {}).get("name")=="checkout-cfg" for x in ef): print("❌ container must envFrom configMapRef checkout-cfg (bulk-inject all keys)"); raise SystemExit(1)
print("✅ envFrom bulk-injects ConfigMap checkout-cfg")
PY
