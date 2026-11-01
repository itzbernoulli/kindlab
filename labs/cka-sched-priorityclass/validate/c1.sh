#!/bin/bash
# PriorityClass high-priority=1000000 exists; pod important uses it (.spec.priority=1000000).
PCV=$(kubectl get priorityclass high-priority -o jsonpath='{.value}' 2>/dev/null)
[ "$PCV" = "1000000" ] || { echo "❌ PriorityClass 'high-priority' missing or not value 1000000 (got '${PCV:-none}'). Create it: kubectl create priorityclass high-priority --value=1000000"; exit 1; }
J=$(kubectl -n priority-learn get pod important -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ pod 'important' not found in priority-learn"; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
def fail(m): print("❌ "+m); sys.exit(1)
d=json.loads(os.environ["J"]); sp=d["spec"]
if sp.get("priorityClassName")!="high-priority": fail("pod 'important' priorityClassName is %r, expected high-priority"%sp.get("priorityClassName"))
if sp.get("priority")!=1000000: fail("pod 'important' .spec.priority is %r, expected 1000000 (admission fills it from the PriorityClass)"%sp.get("priority"))
print("✅ high-priority=1000000 and pod 'important' uses it (.spec.priority=1000000)")
PY
