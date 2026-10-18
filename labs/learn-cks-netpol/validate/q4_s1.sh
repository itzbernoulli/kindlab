#!/bin/bash
J=$(kubectl -n netpol-learn get networkpolicy allow-and -o json 2>/dev/null)
[ -z "$J" ] && { echo "❌ NetworkPolicy 'allow-and' not found in netpol-learn"; exit 1; }
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
if len(frm)!=1:
    fail("must be ONE combined 'from' entry (AND). Two separate entries would be OR'd. got %d entries"%len(frm))
peer=frm[0]
ns=(peer.get("namespaceSelector") or {}).get("matchLabels")
pod=(peer.get("podSelector") or {}).get("matchLabels")
if ns!={"kubernetes.io/metadata.name":"monitoring"}: fail("the 'from' entry must include namespaceSelector name=monitoring, got %r"%peer.get("namespaceSelector"))
if pod!={"role":"client"}: fail("the SAME 'from' entry must also include podSelector role=client (AND), got %r"%peer.get("podSelector"))
print("✅ allow-and: one 'from' peer AND-ing namespaceSelector(monitoring) + podSelector(role=client)")
PY
