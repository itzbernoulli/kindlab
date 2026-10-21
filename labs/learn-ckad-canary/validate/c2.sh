#!/bin/bash
J=$(kubectl -n canary-learn get deploy web-canary -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ Deployment 'web-canary' not found"; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
d=json.loads(os.environ['J']); s=d["spec"]
def fail(m): print("❌ "+m); sys.exit(1)
if s.get("replicas")!=1: fail("replicas must be 1")
if s["template"]["spec"]["containers"][0].get("image")!="nginx:1.26": fail("image must be nginx:1.26")
sel=(s.get("selector") or {}).get("matchLabels") or {}
lbl=s["template"]["metadata"].get("labels") or {}
for src,where in ((sel,"selector"),(lbl,"pod labels")):
    if src.get("app")!="web" or src.get("track")!="canary": fail(f"{where} must be app=web AND track=canary (got {src})")
print("✅ web-canary: nginx:1.26, 1 replica, app=web/track=canary")
PY
