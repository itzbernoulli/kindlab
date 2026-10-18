#!/bin/bash
# web-tls must be type kubernetes.io/tls, have tls.crt + tls.key, cert CN=demo.example.com
NS=ingress-learn
J=$(kubectl -n "$NS" get secret web-tls -o json 2>/dev/null)
[ -z "$J" ] && { echo "❌ Secret 'web-tls' not found in $NS. Create it: kubectl -n $NS create secret tls web-tls --cert=tls.crt --key=tls.key"; exit 1; }
export J

CN=$(kubectl -n "$NS" get secret web-tls -o jsonpath='{.data.tls\.crt}' 2>/dev/null \
  | base64 -d 2>/dev/null | openssl x509 -noout -subject 2>/dev/null)
export CN

python3 - <<'PY'
import os,sys,json
def fail(m): print("❌ "+m); sys.exit(1)
s=json.loads(os.environ['J'])
t=s.get("type")
if t!="kubernetes.io/tls": fail("web-tls is type '%s', not kubernetes.io/tls. Recreate with 'kubectl create secret tls'."%t)
d=s.get("data") or {}
if "tls.crt" not in d or not d["tls.crt"]: fail("web-tls is missing key tls.crt.")
if "tls.key" not in d or not d["tls.key"]: fail("web-tls is missing key tls.key.")
cn=os.environ.get("CN","")
if "CN=demo.example.com" not in cn.replace(" ",""):
    fail("web-tls cert subject is '%s' — expected CN=demo.example.com. Regenerate with -subj \"/CN=demo.example.com\"."%(cn.strip() or "<unreadable>"))
print("✅ web-tls: kubernetes.io/tls with tls.crt+tls.key, cert CN=demo.example.com")
PY
