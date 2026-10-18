#!/bin/bash
NS=exam
P=sidecar
PHASE=$(kubectl -n $NS get pod $P -o jsonpath='{.status.phase}' 2>/dev/null)
if [ -z "$PHASE" ]; then echo "❌ pod '$P' not found in namespace $NS"; exit 1; fi
NC=$(kubectl -n $NS get pod $P -o jsonpath='{.spec.containers[*].name}' 2>/dev/null | wc -w | tr -d ' ')
if [ "$NC" -lt 2 ]; then echo "❌ pod '$P' has $NC container(s), expected 2"; exit 1; fi
# find an emptyDir volume name
VOL=$(kubectl -n $NS get pod $P -o jsonpath='{.spec.volumes[?(@.emptyDir)].name}' 2>/dev/null | awk '{print $1}')
if [ -z "$VOL" ]; then echo "❌ no emptyDir volume on pod '$P'"; exit 1; fi
# every container must mount $VOL at /data
MATCH=$(kubectl -n $NS get pod $P -o json 2>/dev/null | python3 -c '
import json,sys
d=json.load(sys.stdin)
vol=sys.argv[1]
ok=0
for c in d["spec"]["containers"]:
    for m in c.get("volumeMounts",[]):
        if m.get("name")==vol and m.get("mountPath")=="/data":
            ok+=1
print(ok)
' "$VOL")
if [ "${MATCH:-0}" -lt 2 ]; then echo "❌ both containers must mount emptyDir '$VOL' at /data (matched ${MATCH:-0})"; exit 1; fi
if [ "$PHASE" != "Running" ]; then echo "❌ pod '$P' phase is $PHASE, expected Running"; exit 1; fi
echo "✅ pod 'sidecar' has 2 containers sharing emptyDir at /data and is Running"; exit 0
