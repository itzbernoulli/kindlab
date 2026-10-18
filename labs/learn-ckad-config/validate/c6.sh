#!/bin/bash
J=$(kubectl -n ckad-config get pod proj-pod -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ pod 'proj-pod' not found"; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
ps=json.loads(os.environ['J'])["spec"]; c=ps["containers"][0]
def fail(m): print("❌ "+m); sys.exit(1)
m=next((x for x in (c.get("volumeMounts") or []) if x.get("mountPath")=="/etc/proj"), None)
if not m: fail("need a volume mounted at /etc/proj")
v=next((x for x in (ps.get("volumes") or []) if x["name"]==m["name"]), None)
pr=(v or {}).get("projected") or {}
srcs=pr.get("sources") or []
has_cm=any((s.get("configMap") or {}).get("name")=="app-config" for s in srcs)
has_sec=any((s.get("secret") or {}).get("name")=="app-secret" for s in srcs)
has_dw=any("downwardAPI" in s for s in srcs)
if not (has_cm and has_sec and has_dw): fail("projected volume must combine configMap app-config + secret app-secret + downwardAPI (got cm=%s secret=%s downward=%s)"%(has_cm,has_sec,has_dw))
print("✅ proj-pod: projected volume at /etc/proj (configMap + secret + downwardAPI)")
PY
