#!/bin/bash
NS=exam
NP=default-deny
EXISTS=$(kubectl -n $NS get networkpolicy $NP -o jsonpath='{.metadata.name}' 2>/dev/null)
if [ -z "$EXISTS" ]; then echo "❌ NetworkPolicy '$NP' not found in namespace $NS"; exit 1; fi
OK=$(kubectl -n $NS get networkpolicy $NP -o json 2>/dev/null | python3 -c '
import json,sys
d=json.load(sys.stdin)
spec=d["spec"]
# empty podSelector selects all pods
sel_all = spec.get("podSelector",{}) in ({}, {"matchLabels":{}}) and not spec.get("podSelector",{}).get("matchExpressions")
types=spec.get("policyTypes",[])
# Ingress in policyTypes and no ingress rules => deny all ingress
deny = ("Ingress" in types) and (not spec.get("ingress"))
print("yes" if (sel_all and deny) else "no")
')
if [ "$OK" != "yes" ]; then echo "❌ default-deny must select all pods (empty podSelector) and deny all ingress (policyTypes: [Ingress], no ingress rules)"; exit 1; fi
echo "✅ default-deny selects all pods and denies all ingress"; exit 0
