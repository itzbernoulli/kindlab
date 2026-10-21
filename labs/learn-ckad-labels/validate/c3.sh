#!/bin/bash
J=$(kubectl -n labels-learn get pods -l app=shop -o json 2>/dev/null); export J
python3 - <<'PY'
import os,json,sys
items=json.loads(os.environ.get('J') or '{"items":[]}').get("items",[])
if len(items)<2: print("❌ expected 2 app=shop pods (got %d)"%len(items)); sys.exit(1)
bad=[it["metadata"]["name"] for it in items if (it["metadata"].get("labels") or {}).get("tier")!="web"]
if bad: print("❌ these app=shop pods lack tier=web: %s"%bad); sys.exit(1)
print("✅ all app=shop pods have tier=web")
PY
