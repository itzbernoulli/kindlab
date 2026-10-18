#!/bin/bash
NS=ingress-learn
T=$(kubectl -n "$NS" get secret web-tls -o jsonpath='{.type}' 2>/dev/null)
if [ -z "$T" ]; then
  echo "❌ Secret web-tls not found in $NS. Create it: kubectl -n $NS create secret tls web-tls --cert=tls.crt --key=tls.key"; exit 1
fi
if [ "$T" != "kubernetes.io/tls" ]; then
  echo "❌ Secret web-tls is type '$T', not kubernetes.io/tls. Recreate with 'kubectl create secret tls'."; exit 1
fi
CRT=$(kubectl -n "$NS" get secret web-tls -o jsonpath='{.data.tls\.crt}' 2>/dev/null)
KEY=$(kubectl -n "$NS" get secret web-tls -o jsonpath='{.data.tls\.key}' 2>/dev/null)
if [ -z "$CRT" ] || [ -z "$KEY" ]; then
  echo "❌ Secret web-tls is missing tls.crt and/or tls.key (crt='${CRT:+set}' key='${KEY:+set}')."; exit 1
fi
echo "✅ Secret web-tls is type kubernetes.io/tls with tls.crt and tls.key"; exit 0
