#!/bin/bash
# affinity-pod: Running on a tier=gold node AND declaring required nodeAffinity tier In [gold].
J=$(kubectl -n sched-learn get pod affinity-pod -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ pod 'affinity-pod' not found in sched-learn"; exit 1; }; export J
NODE=$(kubectl -n sched-learn get pod affinity-pod -o jsonpath='{.spec.nodeName}' 2>/dev/null)
LAB=""
[ -n "$NODE" ] && LAB=$(kubectl get node "$NODE" -o jsonpath='{.metadata.labels.tier}' 2>/dev/null)
export NODE LAB
python3 - <<'PY'
import os,json,sys
def fail(m): print("❌ "+m); sys.exit(1)
d=json.loads(os.environ['J']); sp=d["spec"]; st=d.get("status",{})
req=(((sp.get("affinity") or {}).get("nodeAffinity") or {}).get("requiredDuringSchedulingIgnoredDuringExecution"))
if not req: fail("affinity-pod has no required nodeAffinity (requiredDuringSchedulingIgnoredDuringExecution)")
terms=req.get("nodeSelectorTerms") or []
found=False
for term in terms:
    for e in (term.get("matchExpressions") or []):
        if e.get("key")=="tier" and e.get("operator")=="In" and "gold" in (e.get("values") or []):
            found=True
if not found: fail("required nodeAffinity must match key=tier operator=In values=[gold]")
node=os.environ.get("NODE","")
if not node: fail("affinity-pod is not scheduled yet (is a node labeled tier=gold and does the pod tolerate its taints?)")
if os.environ.get("LAB")!="gold": fail("affinity-pod landed on %r which is not labeled tier=gold"%node)
if st.get("phase")!="Running": fail("affinity-pod phase is %r, expected Running"%st.get("phase"))
print("✅ affinity-pod Running on %s (tier=gold) via required nodeAffinity"%node)
PY
