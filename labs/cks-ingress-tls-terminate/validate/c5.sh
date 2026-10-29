#!/bin/bash
# every spec.rules host on Ingress web must be covered by some spec.tls hosts entry
NS=ingress-learn
J=$(kubectl -n "$NS" get ingress web -o json 2>/dev/null)
[ -z "$J" ] && { echo "❌ Ingress 'web' not found in $NS."; exit 1; }
export J

python3 - <<'PY'
import os,sys,json
def fail(m): print("❌ "+m); sys.exit(1)
spec=json.loads(os.environ['J']).get("spec",{})
rule_hosts={r.get("host") for r in (spec.get("rules") or []) if r.get("host")}
if not rule_hosts: fail("Ingress web has no named rule hosts to protect. Add a rule with host demo.example.com.")
tls_hosts=set()
for e in (spec.get("tls") or []):
    tls_hosts |= set(e.get("hosts") or [])
if not tls_hosts: fail("Ingress web has no spec.tls hosts — the routed host is served over plain HTTP. Add a tls hosts entry.")
missing=sorted(rule_hosts - tls_hosts)
if missing:
    fail("rule host(s) not covered by any spec.tls hosts: %s — they'd be served over plain HTTP. Add each to a tls hosts list."%missing)
print("✅ every spec.rules host is covered by a spec.tls hosts entry (no plain-HTTP-only host)")
PY
