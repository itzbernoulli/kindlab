#!/bin/bash
J=$(kubectl -n cni-learn get svc web-np -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ Service 'web-np' not found in cni-learn — create the NodePort Service"; exit 1; }; export J
NEP=$(kubectl -n cni-learn get endpointslices -l kubernetes.io/service-name=web-np -o jsonpath='{range .items[*].endpoints[*]}{.addresses[0]}{"\n"}{end}' 2>/dev/null | grep -c .); export NEP
python3 - <<'PY'
import os,json,sys
def fail(m): print("❌ "+m); sys.exit(1)
s=json.loads(os.environ['J'])["spec"]
if s.get("type")!="NodePort": fail("web-np must be type NodePort (got %s)"%s.get("type"))
if s.get("selector",{}).get("app")!="web": fail("web-np selector must be app=web (got %s)"%s.get("selector"))
p=next((p for p in (s.get("ports") or []) if p.get("port")==80), None)
if not p: fail("web-np must expose service port 80")
if p.get("nodePort")!=30080: fail("web-np nodePort must be 30080 (got %s)"%p.get("nodePort"))
addrs=range(int(os.environ.get("NEP","0")))
if len(addrs)<1: fail("web-np has no endpoints — the selector must match the running web pods")
print("✅ web-np: NodePort, port 80, nodePort 30080, selector app=web, %d endpoints"%len(addrs))
PY
