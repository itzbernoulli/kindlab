#!/bin/bash
NS=cks-supply
P=digest-pod
J=$(kubectl -n "$NS" get pod "$P" -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ pod '$P' not found in $NS. Create it with an image pinned by busybox@sha256:<64-hex>."; exit 1; }; export J
python3 - <<'PY'
import os,json,sys,re
c=json.loads(os.environ['J'])["spec"]["containers"][0]
def fail(m): print("❌ "+m); sys.exit(1)
img=c.get("image","")
if not re.match(r'^busybox@sha256:[0-9a-f]{64}$', img):
    fail("image %r is not pinned by a 64-hex busybox digest. Use busybox@sha256:<64-hex-digest> (not a tag)."%img)
print("✅ digest-pod image pinned by digest (%s)"%img)
PY
