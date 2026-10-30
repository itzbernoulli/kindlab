#!/bin/bash
if ! kubectl get crd widgets.stable.example.com >/dev/null 2>&1; then
  echo "❌ CRD widgets.stable.example.com is missing — complete step 1 first"; exit 1
fi
J=$(kubectl -n crd-learn get widget widget2 -o json 2>/dev/null)
[ -z "$J" ] && { echo "❌ second Widget 'widget2' not found — create another Widget named widget2 (spec.size=7, spec.color=red) in crd-learn"; exit 1; }
COUNT=$(kubectl -n crd-learn get widgets --no-headers 2>/dev/null | grep -c .)
export J COUNT
python3 - <<'PY'
import os,json,sys
w=json.loads(os.environ['J'])
def fail(m): print("❌ "+m); sys.exit(1)
spec=w.get("spec") or {}
if spec.get("size")!=7: fail("widget2 spec.size must be 7 (got %r)"%spec.get("size"))
if spec.get("color")!="red": fail("widget2 spec.color must be red (got %r)"%spec.get("color"))
n=int(os.environ.get("COUNT") or 0)
if n<2: fail("expected at least 2 Widgets in crd-learn (got %d) — create widget2 alongside gadget"%n)
print("✅ crd-learn has %d Widgets including widget2 (size=7 color=red; listable via plural/shortName)"%n)
PY
