#!/bin/bash
J=$(kubectl -n workloads-learn get cronjob nightly -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ CronJob 'nightly' not found"; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
s=json.loads(os.environ['J'])["spec"]
def fail(m): print("❌ "+m); sys.exit(1)
if s.get("suspend") is not True: fail("suspend must be true")
if s.get("startingDeadlineSeconds")!=60: fail("startingDeadlineSeconds must be 60")
if s.get("successfulJobsHistoryLimit")!=2: fail("successfulJobsHistoryLimit must be 2")
if s.get("failedJobsHistoryLimit")!=1: fail("failedJobsHistoryLimit must be 1")
print("✅ CronJob nightly: suspend true, startingDeadline 60, history 2/1")
PY
