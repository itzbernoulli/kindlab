#!/bin/bash
J=$(kubectl -n hpa-learn get hpa cache-hpa -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ HPA 'cache-hpa' not found"; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
s=json.loads(os.environ['J'])["spec"]
def fail(m): print("❌ "+m); sys.exit(1)
if (s.get("scaleTargetRef") or {}).get("name")!="cache": fail("scaleTargetRef must be cache")
if s.get("minReplicas")!=2 or s.get("maxReplicas")!=8: fail("min 2 / max 8 required")
tv={ (m.get("resource") or {}).get("name"): (m["resource"].get("target") or {}).get("averageUtilization") for m in (s.get("metrics") or []) if m.get("type")=="Resource" }
if tv.get("cpu")!=60 or tv.get("memory")!=75: fail("need BOTH cpu=60%% and memory=75%% metrics (got %r)"%tv)
print("✅ cache-hpa -> cache, cpu 60% + memory 75%, min 2, max 8")
PY
