#!/bin/bash
J=$(kubectl -n netpol-learn get networkpolicy default-deny-egress-allow-dns -o json 2>/dev/null)
[ -z "$J" ] && { echo "❌ NetworkPolicy 'default-deny-egress-allow-dns' not found in netpol-learn"; exit 1; }
export J
python3 - <<'PY'
import os,json,sys
sp=json.loads(os.environ['J'])["spec"]
def fail(m): print("❌ "+m); sys.exit(1)
if sp.get("podSelector") not in ({}, None): fail("podSelector must be empty ({}) to select all pods, got %r"%sp.get("podSelector"))
if "Egress" not in (sp.get("policyTypes") or []): fail("policyTypes must include Egress, got %r"%sp.get("policyTypes"))
eg=sp.get("egress") or []
if len(eg)!=1: fail("expected exactly 1 egress rule, got %d"%len(eg))
to=eg[0].get("to") or []
if len(to)!=1: fail("egress rule must have exactly 1 'to' entry, got %d"%len(to))
if (to[0].get("namespaceSelector") or {}).get("matchLabels")!={"kubernetes.io/metadata.name":"kube-system"}:
    fail("egress 'to' must be namespaceSelector kubernetes.io/metadata.name=kube-system, got %r"%to[0].get("namespaceSelector"))
ports={(p.get("protocol"),p.get("port")) for p in (eg[0].get("ports") or [])}
if ("UDP",53) not in ports: fail("egress must allow UDP/53 for DNS, got ports %r"%sorted(map(str,ports)))
if ("TCP",53) not in ports: fail("egress must ALSO allow TCP/53 for DNS, got ports %r"%sorted(map(str,ports)))
print("✅ default-deny-egress-allow-dns: all pods egress-isolated, DNS UDP+TCP/53 to kube-system")
PY
