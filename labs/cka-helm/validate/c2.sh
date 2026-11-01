#!/bin/bash
# The web release's Deployment now has 3 replicas (upgraded).
J=$(kubectl -n helm-learn get deploy -l app.kubernetes.io/instance=web -o json 2>/dev/null); export J
python3 - <<'PY'
import os,json,sys
def fail(m): print("❌ "+m); sys.exit(1)
items=json.loads(os.environ["J"] or '{"items":[]}').get("items",[])
if not items: fail("no Helm 'web' Deployment in helm-learn (install it first)")
r=items[0]["spec"].get("replicas")
if r!=3: fail("web release should be upgraded to 3 replicas (got %r) — helm upgrade web ./app -n helm-learn --set replicaCount=3"%r)
print("✅ web release upgraded to 3 replicas")
PY
