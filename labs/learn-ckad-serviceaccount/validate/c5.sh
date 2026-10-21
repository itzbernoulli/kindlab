#!/bin/bash
J=$(kubectl -n sa-learn get pod token-pod -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ pod 'token-pod' not found"; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
vols=json.loads(os.environ['J'])["spec"].get("volumes") or []
def fail(m): print("❌ "+m); sys.exit(1)
ok=False
for v in vols:
    for src in ((v.get("projected") or {}).get("sources") or []):
        t=src.get("serviceAccountToken")
        if t and t.get("audience")=="vault" and t.get("expirationSeconds")==3600: ok=True
if not ok: fail("need a projected volume with serviceAccountToken audience=vault, expirationSeconds=3600")
print("✅ token-pod projects a bound serviceAccountToken (audience vault, 3600s)")
PY
