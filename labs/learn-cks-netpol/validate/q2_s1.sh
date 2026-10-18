#!/bin/bash
J=$(kubectl -n netpol-learn get networkpolicy allow-from-client -o json 2>/dev/null)
[ -z "$J" ] && { echo "❌ NetworkPolicy 'allow-from-client' not found in netpol-learn"; exit 1; }
export J
python3 - <<'PY'
import os,json,sys
sp=json.loads(os.environ['J'])["spec"]
def fail(m): print("❌ "+m); sys.exit(1)
if (sp.get("podSelector") or {}).get("matchLabels")!={"app":"web"}: fail("spec.podSelector must match app=web, got %r"%sp.get("podSelector"))
if "Ingress" not in (sp.get("policyTypes") or []): fail("policyTypes must include Ingress, got %r"%sp.get("policyTypes"))
ing=sp.get("ingress") or []
if len(ing)!=1: fail("expected exactly 1 ingress rule, got %d"%len(ing))
frm=ing[0].get("from") or []
if len(frm)!=1: fail("ingress rule must have exactly 1 'from' entry, got %d"%len(frm))
peer=frm[0]
if "namespaceSelector" in peer or "ipBlock" in peer: fail("'from' must be ONLY a podSelector (no namespaceSelector/ipBlock)")
if (peer.get("podSelector") or {}).get("matchLabels")!={"role":"client"}: fail("'from' podSelector must match role=client, got %r"%peer.get("podSelector"))
print("✅ allow-from-client: app=web ← podSelector role=client")
PY
