#!/bin/bash
NS=cks-supply
S=$(kubectl -n "$NS" get secret regcred -o json 2>/dev/null); [ -z "$S" ] && { echo "❌ Secret 'regcred' not found in $NS. Create it: kubectl -n $NS create secret docker-registry regcred --docker-server=registry.internal:5000 --docker-username=ci --docker-password=s3cr3t"; exit 1; }
P=$(kubectl -n "$NS" get pod private-pod -o json 2>/dev/null); [ -z "$P" ] && { echo "❌ pod 'private-pod' not found in $NS. Create it referencing regcred under spec.imagePullSecrets."; exit 1; }
export S P
python3 - <<'PY'
import os,json,sys
s=json.loads(os.environ['S']); p=json.loads(os.environ['P'])
def fail(m): print("❌ "+m); sys.exit(1)
if s.get("type")!="kubernetes.io/dockerconfigjson": fail("Secret regcred type is %r, expected kubernetes.io/dockerconfigjson (use create secret docker-registry)"%s.get("type"))
names=[x.get("name") for x in (p["spec"].get("imagePullSecrets") or [])]
if "regcred" not in names: fail("pod private-pod spec.imagePullSecrets %r does not reference 'regcred'"%names)
print("✅ regcred dockerconfigjson Secret + private-pod references it in imagePullSecrets")
PY
