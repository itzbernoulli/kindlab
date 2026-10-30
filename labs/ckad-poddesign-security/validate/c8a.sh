#!/bin/bash
J=$(kubectl -n pod-design get pod downward-pod -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ pod 'downward-pod' not found in pod-design"; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
c=json.loads(os.environ['J'])["spec"]["containers"][0]; env={e["name"]:e for e in (c.get("env") or [])}
def fail(m): print("❌ "+m); sys.exit(1)
def fref(name): return ((env.get(name,{}).get("valueFrom") or {}).get("fieldRef") or {}).get("fieldPath")
if fref("POD_NAME")!="metadata.name": fail("env POD_NAME must come from fieldRef metadata.name")
if fref("POD_NS")!="metadata.namespace": fail("env POD_NS must come from fieldRef metadata.namespace")
rfr=((env.get("CPU_LIMIT",{}).get("valueFrom") or {}).get("resourceFieldRef") or {}).get("resource")
if rfr!="limits.cpu": fail("env CPU_LIMIT must come from resourceFieldRef limits.cpu (got %r)"%rfr)
print("✅ env POD_NAME/POD_NS (fieldRef) + CPU_LIMIT (resourceFieldRef limits.cpu)")
PY
