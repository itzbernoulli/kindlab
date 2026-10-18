#!/bin/bash
NS=exam
P=consumer
PHASE=$(kubectl -n $NS get pod $P -o jsonpath='{.status.phase}' 2>/dev/null)
if [ -z "$PHASE" ]; then echo "❌ pod '$P' not found in namespace $NS"; exit 1; fi
OK=$(kubectl -n $NS get pod $P -o json 2>/dev/null | python3 -c '
import json,sys
d=json.load(sys.stdin)
c=d["spec"]["containers"][0]
# env APP_MODE from configMapKeyRef app-cfg/APP_MODE
env_ok=False
for e in c.get("env",[]):
    if e.get("name")=="APP_MODE":
        r=e.get("valueFrom",{}).get("configMapKeyRef",{})
        if r.get("name")=="app-cfg" and r.get("key")=="APP_MODE":
            env_ok=True
# secret volume app-sec mounted at /etc/secret
sec_vols={v["name"] for v in d["spec"].get("volumes",[]) if v.get("secret",{}).get("secretName")=="app-sec"}
mnt_ok=any(m.get("name") in sec_vols and m.get("mountPath")=="/etc/secret" for m in c.get("volumeMounts",[]))
print("yes" if (env_ok and mnt_ok) else "env=%s mnt=%s"%(env_ok,mnt_ok))
')
if [ "$OK" != "yes" ]; then echo "❌ consumer must set APP_MODE from configmap and mount secret app-sec at /etc/secret ($OK)"; exit 1; fi
if [ "$PHASE" != "Running" ]; then echo "❌ pod '$P' phase is $PHASE, expected Running"; exit 1; fi
echo "✅ pod 'consumer' has APP_MODE env from configmap and secret mounted at /etc/secret"; exit 0
