#!/bin/bash
# manual-pod: Running and bound to $W2 via spec.nodeName.
[ -z "$W2" ] && { echo "❌ worker node var W2 is empty"; exit 1; }
J=$(kubectl -n sched-learn get pod manual-pod -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ pod 'manual-pod' not found in sched-learn"; exit 1; }; export J
export W2
python3 - <<'PY'
import os,json,sys
def fail(m): print("❌ "+m); sys.exit(1)
w2=os.environ["W2"]
d=json.loads(os.environ['J']); sp=d["spec"]; st=d.get("status",{})
node=sp.get("nodeName")
if not node: fail("manual-pod has no spec.nodeName — set it to %s"%w2)
if node!=w2: fail("manual-pod is bound to %r, not %r — set spec.nodeName: %s"%(node,w2,w2))
if st.get("phase")!="Running": fail("manual-pod phase is %r, expected Running on %s"%(st.get("phase"),w2))
print("✅ manual-pod Running, pinned to %s via nodeName (scheduler bypassed)"%w2)
PY
