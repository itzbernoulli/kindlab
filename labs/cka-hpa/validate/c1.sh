#!/bin/bash
# HPA web -> Deployment web; min 2, max 5, CPU averageUtilization 70%.
J=$(kubectl -n hpa-learn get hpa web -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ HPA 'web' not found in hpa-learn"; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
def fail(m): print("❌ "+m); sys.exit(1)
sp=json.loads(os.environ["J"])["spec"]
ref=sp.get("scaleTargetRef",{})
if ref.get("kind")!="Deployment" or ref.get("name")!="web": fail("scaleTargetRef must be Deployment/web (got %r)"%ref)
if sp.get("minReplicas")!=2: fail("minReplicas must be 2 (got %r)"%sp.get("minReplicas"))
if sp.get("maxReplicas")!=5: fail("maxReplicas must be 5 (got %r)"%sp.get("maxReplicas"))
# CPU target: support autoscaling/v2 metrics[] or v1 targetCPUUtilizationPercentage
tgt=None
for m in (sp.get("metrics") or []):
    r=m.get("resource") or {}
    if r.get("name")=="cpu": tgt=(r.get("target") or {}).get("averageUtilization")
if tgt is None: tgt=sp.get("targetCPUUtilizationPercentage")
if tgt!=70: fail("CPU target must be 70%% utilization (got %r)"%tgt)
print("✅ HPA web -> Deployment web, min 2, max 5, CPU 70%")
PY
