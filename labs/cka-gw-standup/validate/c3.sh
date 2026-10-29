#!/bin/bash
# Step 3: Gateway web-gw — class kindlab-gc + listener http HTTP:80 allowedRoutes from=Same.
J=$(kubectl -n gw-learn get gateway web-gw -o json 2>/dev/null)
[ -z "$J" ] && { echo "❌ Gateway 'web-gw' not found in gw-learn — create it referencing kindlab-gc with listener http HTTP:80"; exit 1; }
export J
python3 - <<'PY'
import os,json,sys
spec=json.loads(os.environ['J'])["spec"]
def fail(m): print("❌ "+m); sys.exit(1)
if spec.get("gatewayClassName")!="kindlab-gc":
    fail("gatewayClassName='%s', expected 'kindlab-gc'"%spec.get("gatewayClassName"))
ls=spec.get("listeners") or []
l=next((x for x in ls if x.get("name")=="http"), None)
if not l: fail("no listener named 'http' (listeners: %s)"%[x.get("name") for x in ls])
if l.get("protocol")!="HTTP": fail("listener 'http' protocol=%r, expected HTTP"%l.get("protocol"))
if l.get("port")!=80: fail("listener 'http' port=%r, expected 80"%l.get("port"))
frm=(((l.get("allowedRoutes") or {}).get("namespaces") or {}).get("from"))
if frm!="Same": fail("listener 'http' allowedRoutes.namespaces.from=%r, expected 'Same'"%frm)
print("✅ Gateway web-gw: class kindlab-gc + listener http HTTP:80 allowedRoutes from=Same")
PY
