#!/bin/bash
J=$(kubectl -n shop get deploy checkout -o json 2>/dev/null)
[ -z "$J" ] && { echo "❌ Deployment 'checkout' not found in namespace shop"; exit 1; }
export J
python3 - <<'PY'
import os,json
d=json.loads(os.environ['J'])
sp=d["spec"]; ps=sp["template"]["spec"]; cs=ps.get("containers",[]) or [{}]; cont=cs[0]
lbl=(sp["template"]["metadata"].get("labels") or {}); sel=((sp.get("selector") or {}).get("matchLabels") or {})
if lbl.get("app")!="checkout" or lbl.get("tier")!="api": print("❌ pod labels must include app=checkout AND tier=api (got %r)"%lbl); raise SystemExit(1)
if sel.get("app")!="checkout": print("❌ selector matchLabels.app must be 'checkout' (got %r)"%sel); raise SystemExit(1)
print("✅ labels app=checkout + tier=api, selector app=checkout")
PY
