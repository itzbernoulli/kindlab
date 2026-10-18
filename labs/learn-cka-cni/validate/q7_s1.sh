#!/bin/bash
J=$(kubectl -n cni-learn get svc web-hl -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ Service 'web-hl' not found in cni-learn — create the headless Service"; exit 1; }; export J
E=$(kubectl -n cni-learn get endpoints web-hl -o json 2>/dev/null); export E="${E:-{}}"
python3 - <<'PY'
import os,json,sys
def fail(m): print("❌ "+m); sys.exit(1)
s=json.loads(os.environ['J'])["spec"]
if s.get("clusterIP")!="None": fail("web-hl must be headless (clusterIP: None), got '%s' — set it at create time"%s.get("clusterIP"))
if s.get("selector",{}).get("app")!="web": fail("web-hl selector must be app=web (got %s)"%s.get("selector"))
if not any(p.get("port")==80 for p in (s.get("ports") or [])): fail("web-hl must expose port 80")
ep=json.loads(os.environ['E'])
addrs=[a for sub in (ep.get("subsets") or []) for a in (sub.get("addresses") or [])]
if len(addrs)<1: fail("web-hl has no endpoints — the selector must match the running web pods")
print("✅ web-hl: headless (clusterIP None), selector app=web, port 80, %d endpoints"%len(addrs))
PY
