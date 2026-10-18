#!/bin/bash
J=$(kubectl -n cni-learn get svc web-np -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ Service 'web-np' not found in cni-learn — create the NodePort Service"; exit 1; }; export J
E=$(kubectl -n cni-learn get endpoints web-np -o json 2>/dev/null); export E="${E:-{}}"
python3 - <<'PY'
import os,json,sys
def fail(m): print("❌ "+m); sys.exit(1)
s=json.loads(os.environ['J'])["spec"]
if s.get("type")!="NodePort": fail("web-np must be type NodePort (got %s)"%s.get("type"))
if s.get("selector",{}).get("app")!="web": fail("web-np selector must be app=web (got %s)"%s.get("selector"))
p=next((p for p in (s.get("ports") or []) if p.get("port")==80), None)
if not p: fail("web-np must expose service port 80")
if p.get("nodePort")!=30080: fail("web-np nodePort must be 30080 (got %s)"%p.get("nodePort"))
ep=json.loads(os.environ['E'])
addrs=[a for sub in (ep.get("subsets") or []) for a in (sub.get("addresses") or [])]
if len(addrs)<1: fail("web-np has no endpoints — the selector must match the running web pods")
print("✅ web-np: NodePort, port 80, nodePort 30080, selector app=web, %d endpoints"%len(addrs))
PY
