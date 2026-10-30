#!/bin/bash
J=$(kubectl -n deploy-learn get deploy cache -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ deployment 'cache' not found"; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
r=(json.loads(os.environ['J'])["spec"]["template"]["spec"]["containers"][0].get("resources") or {})
req=r.get("requests") or {}; lim=r.get("limits") or {}
if req.get("cpu")!="100m" or req.get("memory")!="128Mi": print("❌ requests must be cpu=100m memory=128Mi (got %r)"%req); sys.exit(1)
if lim.get("cpu")!="200m" or lim.get("memory")!="256Mi": print("❌ limits must be cpu=200m memory=256Mi (got %r)"%lim); sys.exit(1)
print("✅ cache resources requests 100m/128Mi + limits 200m/256Mi (set in place)")
PY
