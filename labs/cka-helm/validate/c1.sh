#!/bin/bash
# A Helm-managed Deployment (instance=web) in helm-learn with 2 replicas.
J=$(kubectl -n helm-learn get deploy -l app.kubernetes.io/instance=web -o json 2>/dev/null); export J
python3 - <<'PY'
import os,json,sys
def fail(m): print("❌ "+m); sys.exit(1)
items=json.loads(os.environ["J"] or '{"items":[]}').get("items",[])
if not items: fail("no Deployment labeled app.kubernetes.io/instance=web in helm-learn — install the 'web' release")
d=items[0]
mb=d["metadata"].get("labels",{}).get("app.kubernetes.io/managed-by")
if mb!="Helm": fail("the Deployment isn't Helm-managed (managed-by=%r)"%mb)
if d["spec"].get("replicas")!=2: fail("release 'web' should have replicaCount=2 (Deployment replicas=%r)"%d["spec"].get("replicas"))
print("✅ Helm release web installed in helm-learn with 2 replicas")
PY
