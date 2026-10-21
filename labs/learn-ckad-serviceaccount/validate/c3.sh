#!/bin/bash
J=$(kubectl -n sa-learn get pod locked -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ pod 'locked' not found"; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
if json.loads(os.environ['J'])["spec"].get("automountServiceAccountToken") is not False:
    print("❌ pod 'locked' must set automountServiceAccountToken: false"); sys.exit(1)
print("✅ pod locked has automountServiceAccountToken false")
PY
