#!/bin/bash
J=$(kubectl -n cni-learn get svc web -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ Service 'web' not found in cni-learn — expose the web deployment"; exit 1; }; export J
# Count ready endpoints via EndpointSlice + jsonpath (Endpoints API is deprecated in k8s 1.33+).
NEP=$(kubectl -n cni-learn get endpointslices -l kubernetes.io/service-name=web -o jsonpath='{range .items[*].endpoints[*]}{.addresses[0]}{"\n"}{end}' 2>/dev/null | grep -c .)
export NEP
python3 - <<'PY'
import os,json,sys
def fail(m): print("❌ "+m); sys.exit(1)
s=json.loads(os.environ['J'])["spec"]
if s.get("type","ClusterIP")!="ClusterIP": fail("Service web must be type ClusterIP (got %s)"%s.get("type"))
ports=s.get("ports") or []
if not any(p.get("port")==80 for p in ports): fail("Service web must expose port 80 (got %s)"%[p.get("port") for p in ports])
n=int(os.environ.get("NEP","0"))
if n<3: fail("Service web needs 3 ready endpoints (got %d) — check the selector matches app=web"%n)
print("✅ Service web: ClusterIP, port 80, %d endpoints"%n)
PY
