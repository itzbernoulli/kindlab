#!/bin/bash
J=$(kubectl -n ckad-config get configmap locked-config -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ ConfigMap 'locked-config' not found"; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
d=json.loads(os.environ['J'])
if (d.get("data") or {}).get("FOO")!="bar": print("❌ locked-config must have data FOO=bar"); sys.exit(1)
if d.get("immutable") is not True: print("❌ locked-config must be immutable: true"); sys.exit(1)
print("✅ locked-config: FOO=bar and immutable:true")
PY
