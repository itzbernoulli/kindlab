#!/bin/bash
J=$(kubectl -n netpol-learn get networkpolicy allow-from-cidr -o json 2>/dev/null)
[ -z "$J" ] && { echo "❌ NetworkPolicy 'allow-from-cidr' not found in netpol-learn"; exit 1; }
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
ip=frm[0].get("ipBlock")
if not ip: fail("'from' must be an ipBlock, got %r"%frm[0])
if ip.get("cidr")!="10.0.0.0/16": fail("ipBlock.cidr must be 10.0.0.0/16, got %r"%ip.get("cidr"))
if (ip.get("except") or [])!=["10.0.5.0/24"]: fail("ipBlock.except must be exactly [10.0.5.0/24], got %r"%ip.get("except"))
print("✅ allow-from-cidr: app=web ← ipBlock 10.0.0.0/16 except 10.0.5.0/24")
PY
