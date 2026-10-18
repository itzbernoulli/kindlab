#!/bin/bash
CN=$(kubectl get gatewayclass kindlab-gc -o jsonpath='{.spec.controllerName}' 2>/dev/null)
if [ -n "$CN" ]; then
  echo "✅ GatewayClass 'kindlab-gc' exists (controllerName=$CN)"; exit 0
fi
if ! kubectl get gatewayclass kindlab-gc >/dev/null 2>&1; then
  echo "❌ GatewayClass 'kindlab-gc' not found — create one with any spec.controllerName"; exit 1
fi
echo "❌ GatewayClass 'kindlab-gc' exists but has no spec.controllerName — set one (e.g. kindlab.io/gateway-controller)"; exit 1
