#!/bin/bash
# Deployment rated ready with exact requests/limits (QoS Burstable).
NS=resources-learn
J=$(kubectl -n "$NS" get deploy rated -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ Deployment 'rated' not found in $NS"; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
def fail(m): print("❌ "+m); sys.exit(1)
d=json.loads(os.environ["J"])
c=next((c for c in d["spec"]["template"]["spec"]["containers"] if c.get("name")=="web"),None)
if not c: fail("no container named 'web'")
r=(c.get("resources") or {}); req=r.get("requests") or {}; lim=r.get("limits") or {}
def norm(v): return v
if req.get("cpu")!="100m": fail("cpu request should be 100m (got %r)"%req.get("cpu"))
if req.get("memory")!="64Mi": fail("memory request should be 64Mi (got %r)"%req.get("memory"))
if lim.get("cpu")!="250m": fail("cpu limit should be 250m (got %r)"%lim.get("cpu"))
if lim.get("memory")!="128Mi": fail("memory limit should be 128Mi (got %r)"%lim.get("memory"))
if d.get("status",{}).get("readyReplicas",0)<1: fail("Deployment 'rated' not ready yet")
print("✅ rated ready with requests 100m/64Mi, limits 250m/128Mi (QoS Burstable)")
PY
