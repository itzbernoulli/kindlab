#!/bin/bash
# Step 3: demo-webapp first container image is nginx:1.25 (tag overridden via -f values file) AND replicas still 4.
J=$(kubectl -n helm-learn get deploy demo-webapp -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ Deployment 'demo-webapp' not found in helm-learn — do steps 1-2 first, then upgrade with -f /tmp/override.yaml"; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
d=json.loads(os.environ['J'])
def fail(m): print("❌ "+m); sys.exit(1)
sp=d["spec"]
reps=sp.get("replicas")
if reps!=4: fail("demo-webapp has replicas=%r, expected 4 — keep --set replicaCount=4 on the upgrade"%reps)
cs=sp["template"]["spec"]["containers"]
if not cs: fail("demo-webapp has no containers")
img=cs[0].get("image","")
tag=img.rsplit(":",1)[-1] if ":" in img else ""
if tag!="1.25": fail("first container image is %r, expected tag 1.25 (nginx:1.25). Use a values file: image.tag: \"1.25\" with -f"%img)
print("✅ demo-webapp image is %s (tag 1.25 via -f values file), replicas still 4"%img)
PY
