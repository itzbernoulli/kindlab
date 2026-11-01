#!/bin/bash
# Job batch-job Complete, with 'helper' as a native sidecar (initContainer restartPolicy Always, not a plain container).
NS=sidecar-learn
J=$(kubectl -n "$NS" get job batch-job -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ Job 'batch-job' not found in $NS"; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
def fail(m): print("❌ "+m); sys.exit(1)
d=json.loads(os.environ["J"])
spec=d["spec"]["template"]["spec"]
sc=next((c for c in (spec.get("initContainers") or []) if c.get("name")=="helper"),None)
if not sc: fail("'helper' must be a native sidecar — an initContainer (it's missing or still a plain container)")
if sc.get("restartPolicy")!="Always": fail("sidecar 'helper' needs restartPolicy: Always (got %r)"%sc.get("restartPolicy"))
if any(c.get("name")=="helper" for c in (spec.get("containers") or [])): fail("'helper' is still a plain container too — it should only be a native sidecar (initContainer)")
conds={c["type"]:c["status"] for c in d.get("status",{}).get("conditions",[])}
if conds.get("Complete")!="True": fail("Job 'batch-job' has not Completed (conditions=%r) — with a native sidecar the worker exits and the Job completes"%conds)
print("✅ Job batch-job Complete with 'helper' as a native sidecar")
PY
