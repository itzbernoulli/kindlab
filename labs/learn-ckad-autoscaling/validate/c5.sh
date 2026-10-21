#!/bin/bash
J=$(kubectl -n hpa-learn get deploy broke -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ Deployment 'broke' not found"; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
req=(json.loads(os.environ['J'])["spec"]["template"]["spec"]["containers"][0].get("resources") or {}).get("requests") or {}
if not req.get("cpu"): print("❌ Deployment 'broke' still has no CPU request — the HPA can't compute utilization. Add one (kubectl set resources deployment/broke --requests=cpu=100m)"); sys.exit(1)
print("✅ broke now sets a CPU request (%s) — HPA can compute utilization"%req.get("cpu"))
PY
