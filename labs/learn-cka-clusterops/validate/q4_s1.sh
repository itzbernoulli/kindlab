#!/bin/bash
J=$(kubectl get node "$W1" -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ node '$W1' not found."; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
taints=json.loads(os.environ['J']).get("spec",{}).get("taints") or []
for t in taints:
    if t.get("key")=="workload":
        if t.get("value")!="batch": print("❌ taint 'workload' has value=%r, expected 'batch'"%t.get("value")); sys.exit(1)
        if t.get("effect")!="NoSchedule": print("❌ taint 'workload' has effect=%r, expected 'NoSchedule'"%t.get("effect")); sys.exit(1)
        print("✅ node has taint workload=batch:NoSchedule"); sys.exit(0)
print("❌ no 'workload' taint on the node. Run: kubectl taint nodes <W1> workload=batch:NoSchedule"); sys.exit(1)
PY
