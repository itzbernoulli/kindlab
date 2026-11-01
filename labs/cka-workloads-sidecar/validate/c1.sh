#!/bin/bash
# Deployment web: native sidecar 'log-agent' (initContainer restartPolicy Always) + app container; ready.
NS=sidecar-learn
J=$(kubectl -n "$NS" get deploy web -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ Deployment 'web' not found in $NS"; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
def fail(m): print("❌ "+m); sys.exit(1)
d=json.loads(os.environ["J"])
spec=d["spec"]["template"]["spec"]
sc=next((c for c in (spec.get("initContainers") or []) if c.get("name")=="log-agent"),None)
if not sc: fail("no initContainer named 'log-agent' — a native sidecar goes under initContainers")
if sc.get("restartPolicy")!="Always": fail("initContainer 'log-agent' needs restartPolicy: Always to be a native sidecar (got %r)"%sc.get("restartPolicy"))
if not any(c.get("name")=="app" for c in (spec.get("containers") or [])): fail("no app container named 'app' under containers")
rr=d.get("status",{}).get("readyReplicas",0)
if rr<1: fail("Deployment 'web' has no ready replica yet (readyReplicas=%s) — give it a moment"%rr)
print("✅ Deployment web ready with native sidecar log-agent (initContainer, restartPolicy: Always)")
PY
