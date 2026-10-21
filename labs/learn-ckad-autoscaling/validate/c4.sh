#!/bin/bash
J=$(kubectl -n hpa-learn get hpa worker-hpa -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ HPA 'worker-hpa' not found"; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
s=json.loads(os.environ['J'])["spec"]
def fail(m): print("❌ "+m); sys.exit(1)
if (s.get("scaleTargetRef") or {}).get("name")!="worker": fail("scaleTargetRef must be worker")
if s.get("minReplicas")!=1 or s.get("maxReplicas")!=5: fail("min 1 / max 5 required")
cpu=[m for m in (s.get("metrics") or []) if (m.get("resource") or {}).get("name")=="cpu"]
if not cpu or (cpu[0]["resource"].get("target") or {}).get("averageUtilization")!=50: fail("need CPU metric at 50%%")
w=((s.get("behavior") or {}).get("scaleDown") or {}).get("stabilizationWindowSeconds")
if w!=300: fail("behavior.scaleDown.stabilizationWindowSeconds must be 300 (got %r)"%w)
print("✅ worker-hpa: cpu 50%, min 1, max 5, scaleDown stabilization 300")
PY
