#!/bin/bash
# Secret db-cred must exist in default on cluster1 (password=s3cr3t) and be absent on cluster2.
J=$(kubectl --context "$CTX" -n default get secret db-cred -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ Secret 'db-cred' not found in default on cluster1 ($CTX): kubectl --context $CTX -n default create secret generic db-cred --from-literal=password=s3cr3t"; exit 1; }; export J
ON2=$(kubectl --context "$CTX2" -n default get secret db-cred -o name 2>/dev/null)
if [ -n "$ON2" ]; then echo "❌ db-cred also exists in default on cluster2 — it must be on cluster1 only (wrong context)"; exit 1; fi
export ON2
python3 - <<'PY'
import os,json,sys,base64
s=json.loads(os.environ['J'])
def fail(m): print("❌ "+m); sys.exit(1)
data=s.get("data") or {}
if "password" not in data: fail("Secret db-cred must have key 'password' (got keys %s)"%sorted(data))
try: v=base64.b64decode(data["password"]).decode()
except Exception: v=None
if v!="s3cr3t": fail("db-cred key 'password' must equal s3cr3t (got %r)"%v)
print("✅ secret 'db-cred' (password=s3cr3t) in default on cluster1 only")
PY
