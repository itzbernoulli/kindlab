#!/bin/bash
J=$(kubectl -n hpa-learn get hpa api-hpa -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ HPA 'api-hpa' not found"; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
s=json.loads(os.environ['J'])["spec"]
def fail(m): print("❌ "+m); sys.exit(1)
if (s.get("scaleTargetRef") or {}).get("name")!="api": fail("scaleTargetRef must be api")
if s.get("minReplicas")!=1 or s.get("maxReplicas")!=6: fail("min 1 / max 6 required")
mem=[m for m in (s.get("metrics") or []) if (m.get("resource") or {}).get("name")=="memory"]
if not mem or (mem[0]["resource"].get("target") or {}).get("averageUtilization")!=80: fail("need a memory metric at 80%% Utilization")
print("✅ api-hpa -> api, memory 80%, min 1, max 6")
PY
