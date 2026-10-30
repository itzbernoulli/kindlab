#!/bin/bash
# DaemonSet node-agent: desiredNumberScheduled == node count and numberReady matches.
NODES=$(kubectl get nodes --no-headers 2>/dev/null | grep -c .)
J=$(kubectl -n sched-learn get ds node-agent -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ DaemonSet 'node-agent' not found in sched-learn"; exit 1; }; export J
export NODES
python3 - <<'PY'
import os,json,sys
def fail(m): print("❌ "+m); sys.exit(1)
nodes=int(os.environ["NODES"] or 0)
if nodes<1: fail("could not count cluster nodes")
st=json.loads(os.environ['J']).get("status",{})
des=st.get("desiredNumberScheduled",0); rdy=st.get("numberReady",0)
if des!=nodes: fail("node-agent is scheduled on %d of %d nodes — add tolerations:[{operator:Exists}] to cover the control plane and the tainted worker"%(des,nodes))
if rdy!=nodes: fail("node-agent has %d/%d pods ready — wait for all to start, or check the image/command"%(rdy,nodes))
print("✅ DaemonSet node-agent runs one ready pod on all %d nodes"%nodes)
PY
