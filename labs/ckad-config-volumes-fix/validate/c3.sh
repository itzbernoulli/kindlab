#!/bin/bash
J=$(kubectl -n ckad-config get pod cfg-vol -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ pod 'cfg-vol' not found"; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
ps=json.loads(os.environ['J'])["spec"]; c=ps["containers"][0]
def fail(m): print("❌ "+m); sys.exit(1)
m=next((x for x in (c.get("volumeMounts") or []) if x.get("mountPath")=="/etc/config"), None)
if not m: fail("need a volume mounted at /etc/config")
v=next((x for x in (ps.get("volumes") or []) if x["name"]==m["name"]), None)
cm=(v or {}).get("configMap") or {}
if cm.get("name")!="app-config": fail("/etc/config must mount configMap app-config")
items=cm.get("items") or []
if not any(it.get("key")=="APP_MODE" and it.get("path")=="mode" for it in items): fail("items must map key APP_MODE -> path mode")
print("✅ cfg-vol: configMap app-config at /etc/config, item APP_MODE→mode")
PY
