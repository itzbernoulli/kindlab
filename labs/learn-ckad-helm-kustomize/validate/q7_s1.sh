#!/bin/bash
# Step 7: namePrefix+commonLabels+replicas => Deployment prod-hello with label tier=frontend and replicas 5.
J=$(kubectl -n kustomize-learn get deploy prod-hello -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ Deployment 'prod-hello' not found in kustomize-learn — add namePrefix: prod- and re-apply: kubectl apply -k /tmp/kustomize-ckad"; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
d=json.loads(os.environ['J'])
def fail(m): print("❌ "+m); sys.exit(1)
tier=d.get("metadata",{}).get("labels",{}).get("tier")
if tier!="frontend": fail("prod-hello label tier=%r, expected 'frontend' — add commonLabels: {tier: frontend}"%tier)
reps=d["spec"].get("replicas")
if reps!=5: fail("prod-hello replicas=%r, expected 5 — add a replicas transform setting hello to 5"%reps)
print("✅ prod-hello in kustomize-learn has label tier=frontend and replicas 5")
PY
