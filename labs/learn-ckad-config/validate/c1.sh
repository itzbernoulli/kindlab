#!/bin/bash
J=$(kubectl -n ckad-config get pod cfg-env -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ pod 'cfg-env' not found"; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
c=json.loads(os.environ['J'])["spec"]["containers"][0]; env={e["name"]:e for e in (c.get("env") or [])}
def fail(m): print("❌ "+m); sys.exit(1)
m=((env.get("MODE",{}).get("valueFrom") or {}).get("configMapKeyRef") or {})
if m.get("name")!="app-config" or m.get("key")!="APP_MODE": fail("env MODE must be configMapKeyRef app-config/APP_MODE")
e=((env.get("EXTRA",{}).get("valueFrom") or {}).get("configMapKeyRef") or {})
if e.get("name")!="app-config" or e.get("key")!="OPTIONAL_KEY": fail("env EXTRA must be configMapKeyRef app-config/OPTIONAL_KEY")
if e.get("optional") is not True: fail("EXTRA's configMapKeyRef must be optional: true")
print("✅ cfg-env: MODE←app-config/APP_MODE + EXTRA←OPTIONAL_KEY (optional)")
PY
