#!/bin/bash
J=$(kubectl -n workloads-learn get cronjob report -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ CronJob 'report' not found"; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
s=json.loads(os.environ['J'])["spec"]
def fail(m): print("❌ "+m); sys.exit(1)
if s.get("schedule")!="*/5 * * * *": fail("schedule must be '*/5 * * * *' (got %r)"%s.get("schedule"))
if s.get("concurrencyPolicy")!="Forbid": fail("concurrencyPolicy must be Forbid")
print("✅ CronJob report: schedule */5, concurrencyPolicy Forbid")
PY
