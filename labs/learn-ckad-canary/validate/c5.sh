#!/bin/bash
kubectl -n canary-learn get svc pay >/dev/null 2>&1 || { echo "❌ Service 'pay' not found (don't delete it — loosen its selector)"; exit 1; }
J=$(kubectl -n canary-learn get endpoints pay -o json 2>/dev/null); export J
python3 - <<'PY'
import os,json,sys
d=json.loads(os.environ.get('J') or '{}')
names=[ (a.get("targetRef") or {}).get("name","") for sub in (d.get("subsets") or []) for a in (sub.get("addresses") or []) ]
if not any(n.startswith("pay-canary-") for n in names):
    print("❌ pay still excludes the canary — its selector is too specific (track=stable). Loosen spec.selector to just app=pay"); sys.exit(1)
print("✅ pay endpoints now include pay-canary pods (selector loosened)")
PY
