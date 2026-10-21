#!/bin/bash
J=$(kubectl -n canary-learn get endpoints web -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ Service 'web' / its endpoints not found"; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
d=json.loads(os.environ['J'])
names=[ (a.get("targetRef") or {}).get("name","") for sub in (d.get("subsets") or []) for a in (sub.get("addresses") or []) ]
st=sum(1 for n in names if n.startswith("web-stable-"))
cn=sum(1 for n in names if n.startswith("web-canary-"))
if st<3 or cn<1:
    print("❌ web endpoints must span both tracks — need >=3 web-stable and >=1 web-canary ready pods (got stable=%d canary=%d). Ensure both Deployments are Ready and the Service selects only app=web"%(st,cn)); sys.exit(1)
print("✅ web endpoints: %d stable + %d canary (traffic split live)"%(st,cn))
PY
