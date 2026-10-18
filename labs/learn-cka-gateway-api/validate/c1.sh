#!/bin/bash
# Step 1: gateways CRD installed and Established.
if ! kubectl get crd gateways.gateway.networking.k8s.io >/dev/null 2>&1; then
  echo "❌ gateways.gateway.networking.k8s.io CRD not found — apply the staged manifest: kubectl apply -f /tmp/gateway-api-crds.yaml"; exit 1
fi
S=$(kubectl get crd gateways.gateway.networking.k8s.io -o jsonpath='{.status.conditions[?(@.type=="Established")].status}' 2>/dev/null)
if [ "$S" = "True" ]; then
  echo "✅ Gateway API CRDs installed (gateways CRD Established)"; exit 0
fi
echo "❌ gateways CRD exists but is not Established yet (status=${S:-none}) — wait for it to establish"; exit 1
