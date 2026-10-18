#!/bin/bash
if ! kubectl get gateway web-gw -n gw-learn >/dev/null 2>&1; then
  echo "❌ Gateway 'web-gw' not found in gw-learn — create it referencing class kindlab-gc with an HTTP listener on 80"; exit 1
fi
GC=$(kubectl get gateway web-gw -n gw-learn -o jsonpath='{.spec.gatewayClassName}' 2>/dev/null)
if [ "$GC" != "kindlab-gc" ]; then
  echo "❌ Gateway 'web-gw' references gatewayClassName='${GC:-none}', expected 'kindlab-gc'"; exit 1
fi
# Find a listener with protocol HTTP on port 80.
HIT=$(kubectl get gateway web-gw -n gw-learn -o jsonpath='{range .spec.listeners[*]}{.protocol}:{.port}{"\n"}{end}' 2>/dev/null | grep -c '^HTTP:80$')
if [ "${HIT:-0}" -ge 1 ]; then
  echo "✅ Gateway 'web-gw' references kindlab-gc and has an HTTP listener on port 80"; exit 0
fi
LST=$(kubectl get gateway web-gw -n gw-learn -o jsonpath='{range .spec.listeners[*]}{.protocol}:{.port} {end}' 2>/dev/null)
echo "❌ Gateway 'web-gw' has no HTTP:80 listener (listeners: ${LST:-none}) — add a listener protocol=HTTP port=80"; exit 1
