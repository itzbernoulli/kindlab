#!/bin/bash
J=$(kubectl -n hpa-learn get hpa web-hpa -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ HPA 'web-hpa' not found"; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
s=json.loads(os.environ['J'])["spec"]
def fail(m): print("❌ "+m); sys.exit(1)
if (s.get("scaleTargetRef") or {}).get("name")!="web": fail("scaleTargetRef must be Deployment web")
if s.get("minReplicas")!=2 or s.get("maxReplicas")!=10: fail("min 2 / max 10 required (got %s/%s)"%(s.get("minReplicas"),s.get("maxReplicas")))
cpu=[m for m in (s.get("metrics") or []) if (m.get("resource") or {}).get("name")=="cpu"]
if not cpu or (cpu[0]["resource"].get("target") or {}).get("averageUtilization")!=70: fail("need a CPU metric at 70%% Utilization")
print("✅ web-hpa -> web, min 2, max 10, CPU 70%")
PY
