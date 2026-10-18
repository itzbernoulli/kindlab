#!/bin/bash
# HTTPRoute from step 4 must still exist and point at hello.
HR_BE=$(kubectl get httproute web-route -n gw-learn -o jsonpath='{range .spec.rules[*].backendRefs[*]}{.name}{"\n"}{end}' 2>/dev/null | grep -c '^hello$')
if ! kubectl get httproute web-route -n gw-learn >/dev/null 2>&1 || [ "${HR_BE:-0}" -lt 1 ]; then
  echo "❌ HTTPRoute 'web-route' (to Service hello) must exist from step 4 before contrasting with Ingress"; exit 1
fi
# Ingress must exist and route to hello.
if ! kubectl get ingress web-ing -n gw-learn >/dev/null 2>&1; then
  echo "❌ Ingress 'web-ing' not found in gw-learn — create the equivalent Ingress routing hello.example.com/ to Service hello:80"; exit 1
fi
ING_BE=$(kubectl get ingress web-ing -n gw-learn -o jsonpath='{range .spec.rules[*].http.paths[*]}{.backend.service.name}{"\n"}{end}' 2>/dev/null | grep -c '^hello$')
if [ "${ING_BE:-0}" -lt 1 ]; then
  BEL=$(kubectl get ingress web-ing -n gw-learn -o jsonpath='{range .spec.rules[*].http.paths[*]}{.backend.service.name} {end}' 2>/dev/null)
  echo "❌ Ingress 'web-ing' does not route to Service 'hello' (backends: ${BEL:-none}) — point a path at hello:80"; exit 1
fi
echo "✅ Both HTTPRoute 'web-route' and Ingress 'web-ing' route to the hello Service — same routing, two APIs"; exit 0
