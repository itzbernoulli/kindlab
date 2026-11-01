#!/bin/bash
# Widget 'gadget' in crd-learn with spec.size == large.
kubectl get crd widgets.example.com >/dev/null 2>&1 || { echo "❌ the Widget CRD isn't installed yet (step 1)"; exit 1; }
J=$(kubectl -n crd-learn get widget gadget -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ Widget 'gadget' not found in crd-learn"; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
def fail(m): print("❌ "+m); sys.exit(1)
d=json.loads(os.environ["J"])
size=(d.get("spec") or {}).get("size")
if size!="large": fail("Widget gadget spec.size is %r, expected 'large'"%size)
print("✅ Widget gadget exists in crd-learn with spec.size=large")
PY
