#!/bin/bash
NS=exam
NP=allow-web
EXISTS=$(kubectl -n $NS get networkpolicy $NP -o jsonpath='{.metadata.name}' 2>/dev/null)
if [ -z "$EXISTS" ]; then echo "❌ NetworkPolicy '$NP' not found in namespace $NS"; exit 1; fi
OK=$(kubectl -n $NS get networkpolicy $NP -o json 2>/dev/null | python3 -c '
import json,sys
d=json.load(sys.stdin)
spec=d["spec"]
sel = spec.get("podSelector",{}).get("matchLabels",{}).get("app")=="clip"
allow=False
for rule in spec.get("ingress",[]):
    for frm in rule.get("from",[]):
        ps=frm.get("podSelector",{}).get("matchLabels",{})
        if ps.get("role")=="frontend":
            allow=True
print("yes" if (sel and allow) else "no")
')
if [ "$OK" != "yes" ]; then echo "❌ allow-web must select app=clip and allow ingress from podSelector role=frontend"; exit 1; fi
echo "✅ allow-web permits ingress to app=clip only from role=frontend"; exit 0
