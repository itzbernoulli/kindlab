#!/bin/bash
if ! kubectl get httproute web-route -n gw-learn >/dev/null 2>&1; then
  echo "❌ HTTPRoute 'web-route' not found in gw-learn — create it with a parentRef to web-gw and a backendRef to the hello Service"; exit 1
fi
PR=$(kubectl get httproute web-route -n gw-learn -o jsonpath='{range .spec.parentRefs[*]}{.name}{"\n"}{end}' 2>/dev/null | grep -c '^web-gw$')
if [ "${PR:-0}" -lt 1 ]; then
  PRL=$(kubectl get httproute web-route -n gw-learn -o jsonpath='{range .spec.parentRefs[*]}{.name} {end}' 2>/dev/null)
  echo "❌ HTTPRoute 'web-route' has no parentRef to 'web-gw' (parentRefs: ${PRL:-none}) — attach it to the Gateway"; exit 1
fi
BE=$(kubectl get httproute web-route -n gw-learn -o jsonpath='{range .spec.rules[*].backendRefs[*]}{.name}{"\n"}{end}' 2>/dev/null | grep -c '^hello$')
if [ "${BE:-0}" -lt 1 ]; then
  BEL=$(kubectl get httproute web-route -n gw-learn -o jsonpath='{range .spec.rules[*].backendRefs[*]}{.name} {end}' 2>/dev/null)
  echo "❌ HTTPRoute 'web-route' does not forward to Service 'hello' (backendRefs: ${BEL:-none}) — add a backendRef name=hello port=80"; exit 1
fi
echo "✅ HTTPRoute 'web-route' attaches to Gateway web-gw and forwards to Service hello"; exit 0
