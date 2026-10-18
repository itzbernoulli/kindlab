#!/bin/bash
J=$(kubectl -n deploy-learn get deploy worker -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ deployment 'worker' not found"; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
c=json.loads(os.environ['J'])["spec"]["template"]["spec"]["containers"][0]
env={e["name"]:e for e in (c.get("env") or [])}
def src(n): return ((env.get(n,{}).get("valueFrom") or {}).get("configMapKeyRef") or {}).get("name")
miss=[k for k in ("LOG_LEVEL","REGION") if src(k)!="worker-cfg"]
if miss: print("❌ env %s must come from ConfigMap worker-cfg (use: kubectl set env deploy/worker --from=configmap/worker-cfg)"%miss); sys.exit(1)
print("✅ worker env LOG_LEVEL + REGION sourced from ConfigMap worker-cfg")
PY
