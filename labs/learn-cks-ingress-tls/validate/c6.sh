#!/bin/bash
# web-tls rotated: still kubernetes.io/tls with both keys, cert CN now demo.example.com
# (NOT the seeded old.example.com), and Ingress web still references it in spec.tls.
NS=ingress-learn
J=$(kubectl -n "$NS" get secret web-tls -o json 2>/dev/null)
[ -z "$J" ] && { echo "❌ Secret 'web-tls' is gone. Recreate it (same name) from the NEW cert/key."; exit 1; }
export J

CN=$(kubectl -n "$NS" get secret web-tls -o jsonpath='{.data.tls\.crt}' 2>/dev/null \
  | base64 -d 2>/dev/null | openssl x509 -noout -subject 2>/dev/null)
export CN

IJ=$(kubectl -n "$NS" get ingress web -o json 2>/dev/null)
[ -z "$IJ" ] && { echo "❌ Ingress 'web' not found — rotation must keep the Ingress reference intact."; exit 1; }
export IJ

python3 - <<'PY'
import os,sys,json
def fail(m): print("❌ "+m); sys.exit(1)
s=json.loads(os.environ['J'])
if s.get("type")!="kubernetes.io/tls": fail("web-tls is type '%s', not kubernetes.io/tls."%s.get("type"))
d=s.get("data") or {}
if not d.get("tls.crt") or not d.get("tls.key"): fail("web-tls is missing tls.crt and/or tls.key.")
cn=os.environ.get("CN","").replace(" ","")
if "CN=old.example.com" in cn:
    fail("web-tls still holds the STALE cert (CN=old.example.com) — generate a NEW cert for CN=demo.example.com and replace the Secret in place.")
if "CN=demo.example.com" not in cn:
    fail("web-tls cert subject is '%s' — expected CN=demo.example.com after rotation."%(os.environ.get("CN","").strip() or "<unreadable>"))
ispec=json.loads(os.environ['IJ']).get("spec",{})
names=[e.get("secretName") for e in (ispec.get("tls") or [])]
if "web-tls" not in names:
    fail("Ingress web no longer references web-tls in spec.tls (found %s). Don't rename the Secret."%names)
print("✅ web-tls rotated to CN=demo.example.com (still kubernetes.io/tls) and Ingress web still references it")
PY
