#!/bin/bash
NS=exam
P=hardened
PHASE=$(kubectl -n $NS get pod $P -o jsonpath='{.status.phase}' 2>/dev/null)
if [ -z "$PHASE" ]; then echo "❌ pod '$P' not found in namespace $NS"; exit 1; fi
OK=$(kubectl -n $NS get pod $P -o json 2>/dev/null | python3 -c '
import json,sys
d=json.load(sys.stdin)
sc=d["spec"]["containers"][0].get("securityContext",{}) or {}
nonroot=sc.get("runAsNonRoot")
if nonroot is None: nonroot=d["spec"].get("securityContext",{}).get("runAsNonRoot")
uid=sc.get("runAsUser")
if uid is None: uid=d["spec"].get("securityContext",{}).get("runAsUser")
ape=sc.get("allowPrivilegeEscalation")
drop=sc.get("capabilities",{}).get("drop",[])
ok = (nonroot is True) and (uid==1000) and (ape is False) and ("ALL" in drop)
print("yes" if ok else "no")
')
if [ "$OK" != "yes" ]; then echo "❌ container securityContext must set runAsNonRoot=true, runAsUser=1000, allowPrivilegeEscalation=false, capabilities.drop=[ALL]"; exit 1; fi
if [ "$PHASE" != "Running" ]; then echo "❌ pod '$P' phase is $PHASE, expected Running"; exit 1; fi
echo "✅ pod 'hardened' runs non-root (uid 1000), no priv-esc, drops ALL caps, and is Running"; exit 0
