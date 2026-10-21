#!/bin/bash
J=$(kubectl -n canary-learn get svc web -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ Service 'web' not found"; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
s=json.loads(os.environ['J'])["spec"]; p=(s.get("ports") or [{}])[0]
def fail(m): print("❌ "+m); sys.exit(1)
if s.get("type") not in (None,"ClusterIP"): fail("type must be ClusterIP")
if p.get("port")!=80 or str(p.get("targetPort"))!="80": fail("port 80 -> targetPort 80")
sel=s.get("selector") or {}
if sel.get("app")!="web" or "track" in sel: fail("selector must be EXACTLY app=web (no track) — got %r"%sel)
print("✅ Service web: ClusterIP 80->80, selector exactly app=web")
PY
