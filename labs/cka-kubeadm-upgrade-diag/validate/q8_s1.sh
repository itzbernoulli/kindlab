#!/bin/bash
# Step 8 (diagnose & fix): maint-app must be Running on $W1, and $W1 must be schedulable.
# $W1 cordoned -> pod stays Pending; uncordon fixes both.
U=$(kubectl get node "$W1" -o jsonpath='{.spec.unschedulable}' 2>/dev/null)
if [ "$U" = "true" ]; then
  echo "❌ node \$W1 ($W1) is still cordoned (SchedulingDisabled) — that's why maint-app can't schedule. Run: kubectl uncordon $W1"; exit 1
fi
J=$(kubectl -n default get pod maint-app -o json 2>/dev/null)
[ -z "$J" ] && { echo "❌ pod 'maint-app' not found in default (don't delete it — diagnose & fix the node)"; exit 1; }
export J
python3 - <<'PY'
import os,json,sys
p=json.loads(os.environ['J'])
def fail(m): print("❌ "+m); sys.exit(1)
phase=p.get("status",{}).get("phase")
node=p.get("spec",{}).get("nodeName")
w1=os.environ.get("W1","")
if phase!="Running":
    fail("maint-app is '%s', not Running — uncordon its target worker so the scheduler can place it"%phase)
if w1 and node!=w1:
    fail("maint-app is Running on '%s' but should be on its pinned worker \$W1 (%s) — don't change its nodeSelector"%(node,w1))
print("✅ maint-app is Running on %s and the node is schedulable"%(node or "?"))
PY
