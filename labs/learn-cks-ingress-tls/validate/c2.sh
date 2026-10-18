#!/bin/bash
# Ingress web must have a spec.tls entry: secretName=web-tls covering host demo.example.com
NS=ingress-learn
J=$(kubectl -n "$NS" get ingress web -o json 2>/dev/null)
[ -z "$J" ] && { echo "❌ Ingress 'web' not found in $NS. Create it with a spec.tls block referencing web-tls."; exit 1; }
export J

python3 - <<'PY'
import os,sys,json
def fail(m): print("❌ "+m); sys.exit(1)
spec=json.loads(os.environ['J']).get("spec",{})
tls=spec.get("tls") or []
if not tls: fail("Ingress web has no spec.tls. Add tls: [{hosts:[demo.example.com], secretName: web-tls}].")
match=[e for e in tls if e.get("secretName")=="web-tls"]
if not match: fail("no spec.tls entry has secretName=web-tls (found secretNames %s)."%[e.get("secretName") for e in tls])
hosts=set()
for e in match: hosts |= set(e.get("hosts") or [])
if "demo.example.com" not in hosts:
    fail("the web-tls tls entry does not list host demo.example.com (lists %s). Set hosts: [demo.example.com]."%sorted(hosts))
print("✅ Ingress web spec.tls references secretName web-tls for host demo.example.com")
PY
