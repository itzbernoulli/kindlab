#!/bin/bash
NS=cks-supply
D=web
J=$(kubectl -n "$NS" get deploy "$D" -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ Deployment '$D' not found in $NS. Create it with container 'web', a pinned image, imagePullPolicy IfNotPresent."; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
cs=json.loads(os.environ['J'])["spec"]["template"]["spec"]["containers"]
def fail(m): print("❌ "+m); sys.exit(1)
c=next((x for x in cs if x.get("name")=="web"), None)
if not c: fail("Deployment web must have a container named 'web' (got %s)"%[x.get('name') for x in cs])
img=c.get("image","")
ref=img.split("/")[-1]  # strip registry/path to inspect the tag/digest
if "@sha256:" not in img:
    if ":" not in ref: fail("image %r is untagged (resolves to :latest). Pin an explicit tag or @sha256 digest."%img)
    if ref.endswith(":latest"): fail("image %r uses :latest. Pin an explicit version tag or digest."%img)
ipp=c.get("imagePullPolicy")
if ipp!="IfNotPresent": fail("imagePullPolicy is %r, expected 'IfNotPresent'"%ipp)
print("✅ Deployment web: container 'web', pinned image (%s), imagePullPolicy IfNotPresent"%img)
PY
