#!/bin/bash
J=$(kubectl -n shop get deploy checkout -o json 2>/dev/null)
[ -z "$J" ] && { echo "❌ Deployment 'checkout' not found in namespace shop"; exit 1; }
export J
python3 - <<'PY'
import os,json
d=json.loads(os.environ['J'])
sp=d["spec"]; ps=sp["template"]["spec"]; cs=ps.get("containers",[]) or [{}]; cont=cs[0]
sa=ps.get("serviceAccountName") or ps.get("serviceAccount")
if sa!="checkout-sa": print("❌ serviceAccountName is %r, expected 'checkout-sa'"%sa); raise SystemExit(1)
print("✅ runs under ServiceAccount checkout-sa")
PY
