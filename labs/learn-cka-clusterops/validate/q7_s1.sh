#!/bin/bash
J=$(kubectl get node "$W2" -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ node '$W2' not found."; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
labels=json.loads(os.environ['J']).get("metadata",{}).get("labels") or {}
v=labels.get("disk")
if v is None: print("❌ node has no 'disk' label. Run: kubectl label node <W2> disk=ssd"); sys.exit(1)
if v!="ssd": print("❌ label disk=%r, expected 'ssd'"%v); sys.exit(1)
print("✅ node has label disk=ssd"); sys.exit(0)
PY
