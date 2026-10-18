#!/bin/bash
# $W1 tainted workload=batch:NoSchedule; batch-pod Running on $W1 with a matching Equal toleration.
[ -z "$W1" ] && { echo "❌ worker node var W1 is empty"; exit 1; }
NJ=$(kubectl get node "$W1" -o json 2>/dev/null); [ -z "$NJ" ] && { echo "❌ node '$W1' not found"; exit 1; }; export NJ
J=$(kubectl -n sched-learn get pod batch-pod -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ pod 'batch-pod' not found in sched-learn"; exit 1; }; export J
export W1
python3 - <<'PY'
import os,json,sys
def fail(m): print("❌ "+m); sys.exit(1)
w1=os.environ["W1"]
n=json.loads(os.environ["NJ"])
taints=n["spec"].get("taints") or []
t=next((x for x in taints if x.get("key")=="workload"),None)
if not t or t.get("value")!="batch" or t.get("effect")!="NoSchedule":
    fail("node %s is not tainted workload=batch:NoSchedule (got %r)"%(w1,t))
d=json.loads(os.environ["J"]); sp=d["spec"]; st=d.get("status",{})
node=sp.get("nodeName")
if not node: fail("batch-pod is not scheduled yet — it needs the toleration AND nodeSelector to land on %s"%w1)
if node!=w1: fail("batch-pod is on %r, not the tainted node %r — use nodeSelector disktype=ssd"%(node,w1))
tol=sp.get("tolerations") or []
ok=any(x.get("key")=="workload" and x.get("value")=="batch" and x.get("effect")=="NoSchedule" and x.get("operator","Equal")=="Equal" for x in tol)
if not ok: fail("batch-pod lacks a matching toleration {key:workload, operator:Equal, value:batch, effect:NoSchedule}")
if st.get("phase")!="Running": fail("batch-pod phase is %r, expected Running"%st.get("phase"))
print("✅ %s tainted workload=batch:NoSchedule and batch-pod Running there with a matching toleration"%w1)
PY
