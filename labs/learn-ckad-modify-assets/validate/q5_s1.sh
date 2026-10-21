#!/bin/bash
J=$(kubectl -n modify-learn get deploy renamer -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ Deployment 'renamer' not found"; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
conts=json.loads(os.environ['J'])["spec"]["template"]["spec"].get("containers",[])
def fail(m): print("❌ "+m); sys.exit(1)
if len(conts)!=1: fail("Deployment 'renamer' must have EXACTLY one container (got %d: %s) — a naive `apply` of a renamed manifest keeps the old 'nginx' and adds 'web'. Use edit/replace/json-patch"%(len(conts),[c.get('name') for c in conts]))
if conts[0].get("name")!="web": fail("the container must be named 'web' (got %r)"%conts[0].get("name"))
if conts[0].get("image")!="nginx:1.25": fail("image must stay nginx:1.25 (got %r)"%conts[0].get("image"))
print("✅ renamer has exactly one container named 'web' (clean rename)")
PY
