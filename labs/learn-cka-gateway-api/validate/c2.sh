#!/bin/bash
# Step 2: GatewayClass kindlab-gc with exact controllerName.
if ! kubectl get gatewayclass kindlab-gc >/dev/null 2>&1; then
  echo "❌ GatewayClass 'kindlab-gc' not found — create it (cluster-scoped) with spec.controllerName kindlab.io/gateway-controller"; exit 1
fi
CN=$(kubectl get gatewayclass kindlab-gc -o jsonpath='{.spec.controllerName}' 2>/dev/null)
if [ "$CN" = "kindlab.io/gateway-controller" ]; then
  echo "✅ GatewayClass 'kindlab-gc' exists (controllerName=$CN)"; exit 0
fi
echo "❌ GatewayClass 'kindlab-gc' controllerName='${CN:-none}', expected 'kindlab.io/gateway-controller'"; exit 1
