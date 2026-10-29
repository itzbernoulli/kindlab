#!/bin/bash
J=$(kubectl -n netpol-learn get networkpolicy allow-egress-to-db -o json 2>/dev/null)
[ -z "$J" ] && { echo "❌ NetworkPolicy 'allow-egress-to-db' not found in netpol-learn"; exit 1; }
export J
python3 - <<'PY'
import os,json,sys
sp=json.loads(os.environ['J'])["spec"]
def fail(m): print("❌ "+m); sys.exit(1)
if (sp.get("podSelector") or {}).get("matchLabels")!={"app":"web"}: fail("spec.podSelector must match app=web, got %r"%sp.get("podSelector"))
if "Egress" not in (sp.get("policyTypes") or []): fail("policyTypes must include Egress, got %r"%sp.get("policyTypes"))
eg=sp.get("egress") or []
if len(eg)!=1: fail("expected exactly 1 egress rule, got %d"%len(eg))
to=eg[0].get("to") or []
if len(to)!=1: fail("egress rule must have exactly 1 'to' entry, got %d"%len(to))
peer=to[0]
if "namespaceSelector" in peer or "ipBlock" in peer: fail("'to' must be ONLY a podSelector")
if (peer.get("podSelector") or {}).get("matchLabels")!={"app":"db"}: fail("egress 'to' podSelector must match app=db, got %r"%peer.get("podSelector"))
ports=eg[0].get("ports") or []
if len(ports)!=1 or ports[0].get("protocol")!="TCP" or ports[0].get("port")!=5432:
    fail("egress must restrict to exactly TCP/5432, got %r"%ports)
print("✅ allow-egress-to-db: app=web → podSelector app=db on TCP/5432")
PY
