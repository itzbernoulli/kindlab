#!/bin/bash
# ssd-pod: Running, nodeSelector disktype=ssd, and the node it runs on carries disktype=ssd.
J=$(kubectl -n sched-learn get pod ssd-pod -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ pod 'ssd-pod' not found in sched-learn"; exit 1; }; export J
NODE=$(kubectl -n sched-learn get pod ssd-pod -o jsonpath='{.spec.nodeName}' 2>/dev/null)
LAB=""
[ -n "$NODE" ] && LAB=$(kubectl get node "$NODE" -o jsonpath='{.metadata.labels.disktype}' 2>/dev/null)
export NODE LAB
python3 - <<'PY'
import os,json,sys
def fail(m): print("❌ "+m); sys.exit(1)
d=json.loads(os.environ['J']); sp=d["spec"]; st=d.get("status",{})
sel=(sp.get("nodeSelector") or {}).get("disktype")
if sel!="ssd": fail("ssd-pod needs nodeSelector disktype=ssd (got %r)"%sel)
node=os.environ.get("NODE","")
if not node: fail("ssd-pod is not scheduled yet (no .spec.nodeName) — no node is labeled disktype=ssd?")
if os.environ.get("LAB")!="ssd": fail("node %r running ssd-pod is not labeled disktype=ssd — label the target node"%node)
ph=st.get("phase")
if ph!="Running": fail("ssd-pod phase is %r, expected Running"%ph)
print("✅ ssd-pod Running on %s (disktype=ssd) via nodeSelector"%node)
PY
