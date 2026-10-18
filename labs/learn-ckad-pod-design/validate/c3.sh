#!/bin/bash
J=$(kubectl -n pod-design get pod log-pod -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ pod 'log-pod' not found in pod-design"; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
ps=json.loads(os.environ['J'])["spec"]
def fail(m): print("❌ "+m); sys.exit(1)
logger=next((c for c in ps.get("initContainers",[]) if c["name"]=="logger"), None)
if not logger: fail("need a native sidecar: initContainer named 'logger'")
if logger.get("restartPolicy")!="Always": fail("'logger' must set restartPolicy: Always (that is what makes it a native sidecar)")
app=next((c for c in ps.get("containers",[]) if c["name"]=="app"), None)
if not app: fail("missing main container 'app'")
for cont,who in ((logger,"logger"),(app,"app")):
    if not any(m.get("mountPath")=="/var/log" for m in (cont.get("volumeMounts") or [])): fail("%s must mount /var/log"%who)
print("✅ log-pod: native sidecar 'logger' (restartPolicy:Always) + app sharing /var/log")
PY
