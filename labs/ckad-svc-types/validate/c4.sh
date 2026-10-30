#!/bin/bash
J=$(kubectl -n svcnet-learn get svc db-ext -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ Service 'db-ext' not found"; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
s=json.loads(os.environ['J'])["spec"]
def fail(m): print("❌ "+m); sys.exit(1)
if s.get("type")!="ExternalName": fail("type must be ExternalName")
if s.get("externalName")!="db.example.com": fail("externalName must be db.example.com (got %r)"%s.get("externalName"))
print("✅ db-ext ExternalName -> db.example.com")
PY
