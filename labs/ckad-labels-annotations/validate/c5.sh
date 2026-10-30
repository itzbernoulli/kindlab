#!/bin/bash
J=$(kubectl -n labels-learn get deploy exp -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ Deployment 'exp' not found"; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
s=json.loads(os.environ['J'])["spec"]
me=(s.get("selector") or {}).get("matchExpressions") or []
ok=any(e.get("key")=="app" and e.get("operator")=="In" and "exp" in (e.get("values") or []) for e in me)
if not ok: print("❌ selector must use matchExpressions {key:app, operator:In, values:[exp]} (got %r)"%me); sys.exit(1)
lbl=s["template"]["metadata"].get("labels") or {}
if lbl.get("app")!="exp": print("❌ pod template label app must be exp (got %r)"%lbl); sys.exit(1)
print("✅ exp selector matchExpressions app In [exp], pods app=exp")
PY
