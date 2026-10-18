#!/bin/bash
NS=ingress-learn
T=$(kubectl -n "$NS" get secret web-tls -o jsonpath='{.type}' 2>/dev/null)
[ -z "$T" ] && { echo "❌ Secret web-tls is gone. Recreate it (same name) from the NEW cert/key."; exit 1; }
[ "$T" != "kubernetes.io/tls" ] && { echo "❌ web-tls is type '$T', not kubernetes.io/tls."; exit 1; }
CRT=$(kubectl -n "$NS" get secret web-tls -o jsonpath='{.data.tls\.crt}' 2>/dev/null)
KEY=$(kubectl -n "$NS" get secret web-tls -o jsonpath='{.data.tls\.key}' 2>/dev/null)
{ [ -z "$CRT" ] || [ -z "$KEY" ]; } && { echo "❌ web-tls missing tls.crt and/or tls.key."; exit 1; }
# require the cert to have actually changed vs the seeded baseline
BASE=$(cat "$LAB_DIR/.webtls-baseline" 2>/dev/null)
CUR=$(echo "$CRT" | base64 -d 2>/dev/null | openssl x509 -noout -fingerprint -sha256 2>/dev/null)
if [ -n "$BASE" ] && [ "$CUR" = "$BASE" ]; then
  echo "❌ web-tls cert is UNCHANGED — generate a NEW cert/key and replace the Secret (same name)."; exit 1
fi
SN=$(kubectl -n "$NS" get ingress web -o jsonpath='{range .spec.tls[*]}{.secretName}{"\n"}{end}' 2>/dev/null | grep -Fx "web-tls")
[ -z "$SN" ] && { echo "❌ Ingress web no longer references web-tls in spec.tls."; exit 1; }
echo "✅ web-tls rotated (new cert) and Ingress still references it"; exit 0
