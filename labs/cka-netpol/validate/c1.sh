#!/bin/bash
# default-deny: empty podSelector, policyTypes [Ingress], no ingress rules.
J=$(kubectl -n netpol-learn get networkpolicy default-deny -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ NetworkPolicy 'default-deny' not found in netpol-learn"; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
def fail(m): print("❌ "+m); sys.exit(1)
sp=json.loads(os.environ["J"])["spec"]
if sp.get("podSelector") not in ({}, {"matchLabels":{}} ): fail("podSelector must be empty {} to select all pods (got %r)"%sp.get("podSelector"))
if "Ingress" not in (sp.get("policyTypes") or []): fail("policyTypes must include Ingress (got %r)"%sp.get("policyTypes"))
if sp.get("ingress"): fail("there must be NO ingress rules for deny-all (got %r)"%sp.get("ingress"))
print("✅ default-deny: all pods, policyTypes [Ingress], no ingress rules")
PY
