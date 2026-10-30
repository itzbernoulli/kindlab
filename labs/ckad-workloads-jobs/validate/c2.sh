#!/bin/bash
J=$(kubectl -n workloads-learn get job pi -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ Job 'pi' not found"; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
s=json.loads(os.environ['J'])["spec"]
def fail(m): print("❌ "+m); sys.exit(1)
if s.get("completions")!=6: fail("completions must be 6")
if s.get("parallelism")!=2: fail("parallelism must be 2")
if s["template"]["spec"].get("restartPolicy")!="Never": fail("restartPolicy must be Never")
print("✅ Job pi: completions 6, parallelism 2, restartPolicy Never")
PY
