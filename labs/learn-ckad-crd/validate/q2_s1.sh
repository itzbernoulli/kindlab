#!/bin/bash
J=$(kubectl -n crd-learn get widget gadget -o json 2>/dev/null)
[ -z "$J" ] && { echo "❌ Widget 'gadget' not found in crd-learn — create a Widget (apiVersion stable.example.com/v1) named gadget"; exit 1; }
export J
python3 - <<'PY'
import os,json,sys
w=json.loads(os.environ['J'])
def fail(m): print("❌ "+m); sys.exit(1)
if w.get("apiVersion")!="stable.example.com/v1": fail("apiVersion must be stable.example.com/v1 (got %r)"%w.get("apiVersion"))
if w.get("kind")!="Widget": fail("kind must be Widget (got %r)"%w.get("kind"))
spec=w.get("spec") or {}
if spec.get("size")!=3: fail("spec.size must be 3 (got %r)"%spec.get("size"))
if spec.get("color")!="blue": fail("spec.color must be blue (got %r)"%spec.get("color"))
print("✅ Widget 'gadget' in crd-learn with size=3 color=blue")
PY
