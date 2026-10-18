#!/bin/bash
# spread Deployment: required podAntiAffinity + 2 Running pods on 2 distinct nodes.
DJ=$(kubectl -n sched-learn get deploy spread -o json 2>/dev/null); [ -z "$DJ" ] && { echo "❌ Deployment 'spread' not found in sched-learn"; exit 1; }; export DJ
PJ=$(kubectl -n sched-learn get pods -l app=spread -o json 2>/dev/null); export PJ
python3 - <<'PY'
import os,json,sys
def fail(m): print("❌ "+m); sys.exit(1)
dep=json.loads(os.environ['DJ'])
ts=dep["spec"]["template"]["spec"]
aa=((ts.get("affinity") or {}).get("podAntiAffinity") or {}).get("requiredDuringSchedulingIgnoredDuringExecution")
if not aa: fail("spread template has no required podAntiAffinity")
ok=False
for term in aa:
    if term.get("topologyKey")!="kubernetes.io/hostname": continue
    ls=term.get("labelSelector") or {}
    ml=ls.get("matchLabels") or {}
    me=ls.get("matchExpressions") or []
    if ml.get("app")=="spread": ok=True
    for e in me:
        if e.get("key")=="app" and e.get("operator")=="In" and "spread" in (e.get("values") or []): ok=True
if not ok: fail("required podAntiAffinity must use topologyKey kubernetes.io/hostname and select app=spread")
pods=json.loads(os.environ['PJ']).get("items",[])
running=[p for p in pods if p.get("status",{}).get("phase")=="Running"]
if len(running)<2: fail("need 2 Running 'spread' pods (got %d running of %d)"%(len(running),len(pods)))
nodes={p["spec"].get("nodeName") for p in running}
if len(nodes)<2: fail("both spread pods are on the same node %r — required podAntiAffinity must spread them across distinct nodes"%nodes)
print("✅ spread: 2 replicas Running on 2 distinct nodes via required podAntiAffinity")
PY
