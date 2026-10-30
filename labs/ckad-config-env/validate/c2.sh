#!/bin/bash
J=$(kubectl -n ckad-config get pod cfg-envfrom -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ pod 'cfg-envfrom' not found"; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
c=json.loads(os.environ['J'])["spec"]["containers"][0]
ef=[x for x in (c.get("envFrom") or []) if (x.get("configMapRef") or {}).get("name")=="app-config"]
if not ef: print("❌ envFrom must reference configMapRef app-config"); sys.exit(1)
if ef[0].get("prefix")!="CFG_": print("❌ envFrom app-config must have prefix 'CFG_' (got %r)"%ef[0].get("prefix")); sys.exit(1)
print("✅ cfg-envfrom: envFrom app-config with prefix CFG_")
PY
