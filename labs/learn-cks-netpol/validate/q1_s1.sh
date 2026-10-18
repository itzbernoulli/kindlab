#!/bin/bash
J=$(kubectl -n netpol-learn get networkpolicy default-deny-ingress -o json 2>/dev/null)
[ -z "$J" ] && { echo "❌ NetworkPolicy 'default-deny-ingress' not found in netpol-learn"; exit 1; }
export J
python3 - <<'PY'
import os,json,sys
sp=json.loads(os.environ['J'])["spec"]
def fail(m): print("❌ "+m); sys.exit(1)
if sp.get("podSelector") not in ({}, None): fail("podSelector must be empty ({}) to select all pods, got %r"%sp.get("podSelector"))
if "Ingress" not in (sp.get("policyTypes") or []): fail("policyTypes must include Ingress, got %r"%sp.get("policyTypes"))
ing=sp.get("ingress")
if ing not in (None, []): fail("a default-deny must have NO ingress rules, got %r"%ing)
print("✅ default-deny-ingress: empty podSelector, Ingress type, zero ingress rules")
PY
