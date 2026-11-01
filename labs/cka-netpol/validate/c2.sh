#!/bin/bash
# allow-client: dest podSelector app=web; ingress from podSelector role=client; ports TCP/80.
J=$(kubectl -n netpol-learn get networkpolicy allow-client -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ NetworkPolicy 'allow-client' not found in netpol-learn"; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
def fail(m): print("❌ "+m); sys.exit(1)
sp=json.loads(os.environ["J"])["spec"]
if (sp.get("podSelector") or {}).get("matchLabels",{}).get("app")!="web": fail("top-level podSelector must select app=web (the destination) — got %r"%sp.get("podSelector"))
ing=sp.get("ingress") or []
if not ing: fail("no ingress rule")
rule=ing[0]
frm=rule.get("from") or []
if not any((f.get("podSelector") or {}).get("matchLabels",{}).get("role")=="client" for f in frm): fail("ingress.from must include podSelector role=client (the source) — got %r"%frm)
ports=rule.get("ports") or []
if not any(p.get("port")==80 and (p.get("protocol") or "TCP")=="TCP" for p in ports): fail("ingress rule must allow TCP port 80 — got %r"%ports)
print("✅ allow-client: dest app=web, from role=client, TCP/80")
PY
