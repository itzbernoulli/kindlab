#!/bin/bash
J=$(kubectl -n workloads-learn get deploy web -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ Deployment 'web' not found"; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
s=json.loads(os.environ['J'])["spec"]
def fail(m): print("❌ "+m); sys.exit(1)
if s.get("replicas")!=3: fail("replicas must be 3")
if (s.get("strategy") or {}).get("type")!="Recreate": fail("strategy.type must be Recreate")
if s.get("revisionHistoryLimit")!=5: fail("revisionHistoryLimit must be 5 (got %r)"%s.get("revisionHistoryLimit"))
print("✅ web: 3 replicas, strategy Recreate, revisionHistoryLimit 5")
PY
