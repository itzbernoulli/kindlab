#!/bin/bash
J=$(kubectl -n sa-learn get sa deployer -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ ServiceAccount 'deployer' not found"; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
ips=json.loads(os.environ['J']).get("imagePullSecrets") or []
if not any(x.get("name")=="regcred" for x in ips): print("❌ SA deployer must list imagePullSecret 'regcred'"); sys.exit(1)
print("✅ SA deployer imagePullSecret regcred")
PY
T=$(kubectl -n sa-learn get secret regcred -o jsonpath='{.type}' 2>/dev/null)
[ "$T" = "kubernetes.io/dockerconfigjson" ] || { echo "❌ secret 'regcred' must be a docker-registry (dockerconfigjson) secret (got '${T:-missing}')"; exit 1; }
echo "✅ regcred is a dockerconfigjson secret attached to deployer"; exit 0
