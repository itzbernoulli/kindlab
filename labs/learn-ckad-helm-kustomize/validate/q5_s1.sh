#!/bin/bash
# Step 5: /tmp/rendered.yaml exists and contains a rendered Deployment with replicas: 7
# (helm template, no release installed).
F=/tmp/rendered.yaml
if [ ! -f "$F" ]; then
  echo "❌ $F not found — render the chart: helm template demo /tmp/webapp --set replicaCount=7 > $F"; exit 1
fi
export F
python3 - <<'PY'
import os,re,sys
txt=open(os.environ['F']).read()
def fail(m): print("❌ "+m); sys.exit(1)
if not re.search(r'(?m)^\s*kind:\s*Deployment\s*$', txt):
    fail("%s has no 'kind: Deployment' — render the webapp chart with helm template"%os.environ['F'])
if not re.search(r'(?m)^\s*replicas:\s*7\s*$', txt):
    fail("%s has no 'replicas: 7' line — render with --set replicaCount=7"%os.environ['F'])
print("✅ /tmp/rendered.yaml contains a rendered Deployment with replicas: 7 (helm template, no install)")
PY
