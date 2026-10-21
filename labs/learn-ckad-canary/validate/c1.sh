#!/bin/bash
J=$(kubectl -n canary-learn get deploy web-stable -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ Deployment 'web-stable' not found"; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
d=json.loads(os.environ['J']); s=d["spec"]
def fail(m): print("❌ "+m); sys.exit(1)
if s.get("replicas")!=3: fail("replicas must be 3")
if s["template"]["spec"]["containers"][0].get("image")!="nginx:1.25": fail("image must be nginx:1.25")
sel=(s.get("selector") or {}).get("matchLabels") or {}
lbl=s["template"]["metadata"].get("labels") or {}
for src,where in ((sel,"selector"),(lbl,"pod labels")):
    if src.get("app")!="web" or src.get("track")!="stable": fail(f"{where} must be app=web AND track=stable (got {src})")
print("✅ web-stable: nginx:1.25, 3 replicas, app=web/track=stable")
PY
