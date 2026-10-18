#!/bin/bash
J=$(kubectl -n pod-design get pod health-pod -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ pod 'health-pod' not found in pod-design"; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
c=json.loads(os.environ['J'])["spec"]["containers"][0]
def fail(m): print("❌ "+m); sys.exit(1)
sp=c.get("startupProbe") or {}; t=sp.get("tcpSocket") or {}
if str(t.get("port"))!="80": fail("startupProbe must use tcpSocket port 80")
if sp.get("failureThreshold")!=30: fail("startupProbe.failureThreshold must be 30 (got %r)"%sp.get("failureThreshold"))
if sp.get("periodSeconds")!=10: fail("startupProbe.periodSeconds must be 10 (got %r)"%sp.get("periodSeconds"))
print("✅ startupProbe: tcpSocket :80, failureThreshold 30, period 10")
PY
