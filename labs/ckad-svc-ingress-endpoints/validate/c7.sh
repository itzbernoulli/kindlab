#!/bin/bash
J=$(kubectl -n svcnet-learn get svc ext-svc -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ Service 'ext-svc' not found"; exit 1; }
HASSEL=$(echo "$J" | python3 -c "import sys,json;print('yes' if json.load(sys.stdin)['spec'].get('selector') else 'no')")
[ "$HASSEL" = "no" ] || { echo "❌ ext-svc must be selector-less (remove spec.selector)"; exit 1; }
ES=$(kubectl -n svcnet-learn get endpointslice -l kubernetes.io/service-name=ext-svc -o json 2>/dev/null)
export ES
python3 - <<'PY'
import os,json,sys
d=json.loads(os.environ.get('ES') or '{"items":[]}'); items=d.get("items",[])
addrs=[a for it in items for ep in it.get("endpoints",[]) for a in ep.get("addresses",[])]
if "10.40.0.9" not in addrs:
    print("❌ need an EndpointSlice labelled kubernetes.io/service-name=ext-svc with address 10.40.0.9 (got %r)"%addrs); sys.exit(1)
print("✅ ext-svc selector-less + EndpointSlice with 10.40.0.9")
PY
