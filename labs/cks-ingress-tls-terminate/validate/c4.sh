#!/bin/bash
# Ingress web must have spec.ingressClassName == nginx (not the deprecated annotation)
NS=ingress-learn
J=$(kubectl -n "$NS" get ingress web -o json 2>/dev/null)
[ -z "$J" ] && { echo "❌ Ingress 'web' not found in $NS."; exit 1; }
export J

python3 - <<'PY'
import os,sys,json
def fail(m): print("❌ "+m); sys.exit(1)
obj=json.loads(os.environ['J'])
cls=(obj.get("spec",{}) or {}).get("ingressClassName")
if cls is None:
    ann=(obj.get("metadata",{}).get("annotations") or {}).get("kubernetes.io/ingress.class")
    if ann:
        fail("ingress class set via the deprecated annotation ('%s'). Set spec.ingressClassName: nginx instead."%ann)
    fail("spec.ingressClassName is not set. Patch it: kubectl -n ingress-learn patch ingress web --type=merge -p '{\"spec\":{\"ingressClassName\":\"nginx\"}}'.")
if cls!="nginx":
    fail("spec.ingressClassName is '%s', expected 'nginx'."%cls)
print("✅ Ingress web spec.ingressClassName == nginx")
PY
