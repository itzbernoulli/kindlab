#!/bin/bash
J=$(kubectl -n workloads-learn get job indexed -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ Job 'indexed' not found"; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
s=json.loads(os.environ['J'])["spec"]
def fail(m): print("❌ "+m); sys.exit(1)
if s.get("completionMode")!="Indexed": fail("completionMode must be Indexed (got %r)"%s.get("completionMode"))
if s.get("completions")!=4: fail("completions must be 4")
if s.get("parallelism")!=2: fail("parallelism must be 2")
print("✅ Job indexed: Indexed, completions 4, parallelism 2")
PY
