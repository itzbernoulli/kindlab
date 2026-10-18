#!/bin/bash
J=$(kubectl -n shop get deploy checkout -o json 2>/dev/null)
[ -z "$J" ] && { echo "❌ Deployment 'checkout' not found in namespace shop"; exit 1; }
export J
python3 - <<'PY'
import os,json
d=json.loads(os.environ['J'])
sp=d["spec"]; ps=sp["template"]["spec"]; cs=ps.get("containers",[]) or [{}]; cont=cs[0]
e=[x for x in (cont.get("env") or []) if x.get("name")=="API_KEY"]
if not e: print("❌ no env var named API_KEY"); raise SystemExit(1)
skr=(e[0].get("valueFrom") or {}).get("secretKeyRef") or {}
if skr.get("name")!="checkout-sec" or skr.get("key")!="API_KEY": print("❌ API_KEY must come from secretKeyRef checkout-sec key API_KEY (got %r)"%skr); raise SystemExit(1)
print("✅ env API_KEY <- Secret checkout-sec/API_KEY")
PY
