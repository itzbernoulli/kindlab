#!/bin/bash
J=$(kubectl -n shop get deploy checkout -o json 2>/dev/null)
[ -z "$J" ] && { echo "❌ Deployment 'checkout' not found in namespace shop"; exit 1; }
export J
python3 - <<'PY'
import os,json
d=json.loads(os.environ['J'])
sp=d["spec"]; ps=sp["template"]["spec"]; cs=ps.get("containers",[]) or [{}]; cont=cs[0]
m=[x for x in (cont.get("volumeMounts") or []) if x.get("mountPath")=="/var/cache/checkout"]
if not m: print("❌ no volumeMount at /var/cache/checkout"); raise SystemExit(1)
vn=m[0]["name"]; v=[x for x in (ps.get("volumes") or []) if x.get("name")==vn]
if not v or "emptyDir" not in v[0]: print("❌ /var/cache/checkout must be backed by an emptyDir volume"); raise SystemExit(1)
print("✅ emptyDir mounted at /var/cache/checkout")
PY
