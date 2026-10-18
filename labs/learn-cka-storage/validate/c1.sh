#!/bin/bash
J=$(kubectl get sc fast-local -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ StorageClass 'fast-local' not found"; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
d=json.loads(os.environ['J'])
def fail(m): print("❌ "+m); sys.exit(1)
p=d.get("provisioner")
if p!="rancher.io/local-path": fail("provisioner is %r, expected 'rancher.io/local-path'"%p)
r=d.get("reclaimPolicy")
if r!="Delete": fail("reclaimPolicy is %r, expected 'Delete'"%r)
m=d.get("volumeBindingMode")
if m!="WaitForFirstConsumer": fail("volumeBindingMode is %r, expected 'WaitForFirstConsumer'"%m)
print("✅ fast-local: provisioner rancher.io/local-path, reclaimPolicy Delete, WaitForFirstConsumer")
PY
