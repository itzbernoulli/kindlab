#!/bin/bash
J=$(kubectl -n netpol-learn get networkpolicy allow-api -o json 2>/dev/null)
[ -z "$J" ] && { echo "❌ NetworkPolicy 'allow-api' not found in netpol-learn (fix it in place — don't rename or delete it)"; exit 1; }
export J
python3 - <<'PY'
import os,json,sys
sp=json.loads(os.environ['J'])["spec"]
def fail(m): print("❌ "+m); sys.exit(1)
if (sp.get("podSelector") or {}).get("matchLabels")!={"app":"web"}: fail("allow-api must still select app=web, got %r"%sp.get("podSelector"))
if "Ingress" not in (sp.get("policyTypes") or []): fail("policyTypes must include Ingress, got %r"%sp.get("policyTypes"))
ing=sp.get("ingress") or []
if len(ing)!=1: fail("expected exactly 1 ingress rule, got %d"%len(ing))
frm=ing[0].get("from") or []
if len(frm)!=1: fail("ingress rule must have exactly 1 'from' entry, got %d"%len(frm))
peer=frm[0]
if (peer.get("podSelector") or {}).get("matchLabels")!={"role":"client"}:
    fail("'from' podSelector must match role=client (the seed had role=clients — a typo), got %r"%peer.get("podSelector"))
ports=ing[0].get("ports") or []
if len(ports)!=1 or ports[0].get("protocol")!="TCP" or ports[0].get("port")!=8080:
    fail("ingress must allow exactly TCP/8080 (the seed had port 80), got %r"%ports)
print("✅ allow-api fixed: app=web ← podSelector role=client on TCP/8080")
PY
