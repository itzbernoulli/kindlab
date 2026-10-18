#!/bin/bash
J=$(kubectl -n pod-design get pod health-pod -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ pod 'health-pod' not found in pod-design"; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
c=json.loads(os.environ['J'])["spec"]["containers"][0]
def fail(m): print("❌ "+m); sys.exit(1)
rp=c.get("readinessProbe") or {}; h=rp.get("httpGet") or {}
if h.get("path")!="/" or str(h.get("port"))!="80": fail("readinessProbe must be httpGet path / port 80")
if rp.get("initialDelaySeconds")!=5: fail("readinessProbe.initialDelaySeconds must be 5 (got %r)"%rp.get("initialDelaySeconds"))
print("✅ readinessProbe: httpGet / :80, initialDelaySeconds 5")
PY
