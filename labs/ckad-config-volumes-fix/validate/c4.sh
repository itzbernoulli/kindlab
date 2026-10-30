#!/bin/bash
J=$(kubectl -n ckad-config get pod sec-pod -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ pod 'sec-pod' not found"; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
ps=json.loads(os.environ['J'])["spec"]; c=ps["containers"][0]
def fail(m): print("❌ "+m); sys.exit(1)
env={e["name"]:e for e in (c.get("env") or [])}
skr=((env.get("KEY",{}).get("valueFrom") or {}).get("secretKeyRef") or {})
if skr.get("name")!="app-secret" or skr.get("key")!="API_KEY": fail("env KEY must be secretKeyRef app-secret/API_KEY")
m=next((x for x in (c.get("volumeMounts") or []) if x.get("mountPath")=="/etc/secret"), None)
if not m: fail("need a secret volume mounted at /etc/secret")
v=next((x for x in (ps.get("volumes") or []) if x["name"]==m["name"]), None)
sec=(v or {}).get("secret") or {}
if sec.get("secretName")!="app-secret": fail("/etc/secret must mount secret app-secret")
if sec.get("defaultMode")!=256: fail("secret volume defaultMode must be 0400 (=256), got %r"%sec.get("defaultMode"))
print("✅ sec-pod: env KEY←app-secret/API_KEY + secret volume at /etc/secret (0400)")
PY
