#!/bin/bash
NS=exam
ING=shop-ing
EXISTS=$(kubectl -n $NS get ingress $ING -o jsonpath='{.metadata.name}' 2>/dev/null)
if [ -z "$EXISTS" ]; then echo "❌ Ingress '$ING' not found in namespace $NS"; exit 1; fi
OK=$(kubectl -n $NS get ingress $ING -o json 2>/dev/null | python3 -c '
import json,sys
d=json.load(sys.stdin)
for r in d["spec"].get("rules",[]):
    if r.get("host")!="shop.example.com": continue
    for p in r.get("http",{}).get("paths",[]):
        svc=p.get("backend",{}).get("service",{})
        port=svc.get("port",{})
        if p.get("path")=="/" and p.get("pathType")=="Prefix" and svc.get("name")=="clip-svc" and port.get("number")==80:
            print("yes"); sys.exit(0)
print("no")
')
if [ "$OK" != "yes" ]; then echo "❌ Ingress must route host shop.example.com, path / (Prefix) to clip-svc:80"; exit 1; fi
echo "✅ Ingress 'shop-ing' routes shop.example.com/ to clip-svc:80"; exit 0
