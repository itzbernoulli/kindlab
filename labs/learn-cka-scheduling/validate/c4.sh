#!/bin/bash
# prefer-pod: Running AND declaring preferred nodeAffinity weight 80 matching zone In [b].
J=$(kubectl -n sched-learn get pod prefer-pod -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ pod 'prefer-pod' not found in sched-learn"; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
def fail(m): print("❌ "+m); sys.exit(1)
d=json.loads(os.environ['J']); sp=d["spec"]; st=d.get("status",{})
pref=(((sp.get("affinity") or {}).get("nodeAffinity") or {}).get("preferredDuringSchedulingIgnoredDuringExecution"))
if not pref: fail("prefer-pod has no preferred nodeAffinity (preferredDuringSchedulingIgnoredDuringExecution)")
ok=False
for p in pref:
    if p.get("weight")!=80: continue
    for e in ((p.get("preference") or {}).get("matchExpressions") or []):
        if e.get("key")=="zone" and e.get("operator")=="In" and "b" in (e.get("values") or []):
            ok=True
if not ok: fail("need a preferred entry weight=80 matching key=zone operator=In values=[b]")
if st.get("phase")!="Running": fail("prefer-pod phase is %r, expected Running"%st.get("phase"))
print("✅ prefer-pod Running with preferred nodeAffinity weight 80, zone In [b]")
PY
