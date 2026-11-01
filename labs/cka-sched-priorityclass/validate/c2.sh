#!/bin/bash
# vip Running on $W1; at least one low-priority ballast pod was preempted (fewer than 2 remain).
[ -z "$W1" ] && { echo "❌ worker var W1 is empty"; exit 1; }
V=$(kubectl -n priority-learn get pod vip -o json 2>/dev/null); [ -z "$V" ] && { echo "❌ pod 'vip' not found — create a demo-high pod to trigger preemption"; exit 1; }
BAL=$(kubectl -n priority-learn get pods -l role=ballast -o json 2>/dev/null); export V BAL W1
python3 - <<'PY'
import os,json,sys
def fail(m): print("❌ "+m); sys.exit(1)
w1=os.environ["W1"]
v=json.loads(os.environ["V"]); vs=v.get("status",{}); vspec=v["spec"]
if vspec.get("priorityClassName")!="demo-high": fail("'vip' must use priorityClassName demo-high (got %r)"%vspec.get("priorityClassName"))
if vs.get("phase")!="Running": fail("'vip' is %r, not Running yet — preemption/scheduling may still be in progress"%vs.get("phase"))
if vspec.get("nodeName")!=w1: fail("'vip' landed on %r, not the full node %s"%(vspec.get("nodeName"),w1))
bal=json.loads(os.environ["BAL"]).get("items",[])
running=[b for b in bal if b.get("status",{}).get("phase")=="Running"]
if len(running)>=2: fail("both ballast pods still Running (%d) — vip should have preempted one; it may have found room without preemption"%len(running))
print("✅ vip Running on %s after preempting a low-priority ballast pod (%d ballast remain)"%(w1,len(running)))
PY
