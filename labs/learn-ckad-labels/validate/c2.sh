#!/bin/bash
J=$(kubectl -n labels-learn get pod legacy -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ pod 'legacy' not found"; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
lbl=json.loads(os.environ['J'])["metadata"].get("labels") or {}
def fail(m): print("❌ "+m); sys.exit(1)
if lbl.get("env")!="prod": fail("env must be overwritten to prod (got %r)"%lbl.get("env"))
if "deprecated" in lbl: fail("the 'deprecated' label must be removed (use: kubectl label pod legacy deprecated-)")
print("✅ legacy: env=prod and deprecated removed")
PY
