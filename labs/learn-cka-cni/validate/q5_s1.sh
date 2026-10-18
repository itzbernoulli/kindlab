#!/bin/bash
J=$(kubectl -n cni-learn get svc web -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ Service 'web' not found in cni-learn — expose the web deployment"; exit 1; }; export J
E=$(kubectl -n cni-learn get endpoints web -o json 2>/dev/null); export E="${E:-{}}"
python3 - <<'PY'
import os,json,sys
def fail(m): print("❌ "+m); sys.exit(1)
s=json.loads(os.environ['J'])["spec"]
if s.get("type","ClusterIP")!="ClusterIP": fail("Service web must be type ClusterIP (got %s)"%s.get("type"))
ports=s.get("ports") or []
if not any(p.get("port")==80 for p in ports): fail("Service web must expose port 80 (got %s)"%[p.get("port") for p in ports])
ep=json.loads(os.environ['E'])
addrs=[a for sub in (ep.get("subsets") or []) for a in (sub.get("addresses") or [])]
if len(addrs)<3: fail("Service web needs 3 ready endpoints (got %d) — check the selector matches app=web"%len(addrs))
print("✅ Service web: ClusterIP, port 80, %d endpoints"%len(addrs))
PY
