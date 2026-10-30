#!/bin/bash
# Step 8: configMapGenerator (hash disabled) + namePrefix => ConfigMap prod-app-cfg with data.GREETING=hello.
J=$(kubectl -n kustomize-learn get configmap prod-app-cfg -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ ConfigMap 'prod-app-cfg' not found in kustomize-learn — add a configMapGenerator (name app-cfg, literal GREETING=hello) with generatorOptions.disableNameSuffixHash=true, then kubectl apply -k /tmp/kustomize-ckad"; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
d=json.loads(os.environ['J'])
def fail(m): print("❌ "+m); sys.exit(1)
g=d.get("data",{}).get("GREETING")
if g!="hello": fail("prod-app-cfg data.GREETING=%r, expected 'hello'"%g)
print("✅ ConfigMap prod-app-cfg (hash disabled) in kustomize-learn has GREETING=hello")
PY
