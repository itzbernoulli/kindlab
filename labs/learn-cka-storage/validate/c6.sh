#!/bin/bash
J=$(kubectl get sc fast-local -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ StorageClass 'fast-local' not found"; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
ann=(json.loads(os.environ['J']).get("metadata") or {}).get("annotations") or {}
v=ann.get("storageclass.kubernetes.io/is-default-class")
if v!="true": print("❌ fast-local is-default-class annotation is %r, expected the string \"true\""%v); sys.exit(1)
print("✅ fast-local is marked the cluster default (is-default-class=\"true\")")
PY
