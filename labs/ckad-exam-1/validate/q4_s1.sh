#!/bin/bash
NS=exam
P=initdemo
PHASE=$(kubectl -n $NS get pod $P -o jsonpath='{.status.phase}' 2>/dev/null)
if [ -z "$PHASE" ]; then echo "❌ pod '$P' not found in namespace $NS"; exit 1; fi
INIT=$(kubectl -n $NS get pod $P -o jsonpath='{.spec.initContainers[?(@.name=="setup")].name}' 2>/dev/null)
if [ "$INIT" != "setup" ]; then echo "❌ init container 'setup' missing"; exit 1; fi
# shared emptyDir mounted at /work in init and main
OK=$(kubectl -n $NS get pod $P -o json 2>/dev/null | python3 -c '
import json,sys
d=json.load(sys.stdin)
eds={v["name"] for v in d["spec"].get("volumes",[]) if "emptyDir" in v}
def mounted(c):
    return any(m.get("name") in eds and m.get("mountPath")=="/work" for m in c.get("volumeMounts",[]))
init=any(mounted(c) for c in d["spec"].get("initContainers",[]))
main=any(mounted(c) for c in d["spec"].get("containers",[]))
print("yes" if (init and main) else "no")
')
if [ "$OK" != "yes" ]; then echo "❌ an emptyDir must be mounted at /work in both the init and main container"; exit 1; fi
if [ "$PHASE" != "Running" ]; then echo "❌ pod '$P' phase is $PHASE, expected Running (init must Complete)"; exit 1; fi
echo "✅ pod 'initdemo' has init container 'setup', shared /work emptyDir, and is Running"; exit 0
