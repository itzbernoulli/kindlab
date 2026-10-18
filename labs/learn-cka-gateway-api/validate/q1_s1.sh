#!/bin/bash
S=$(kubectl get crd gateways.gateway.networking.k8s.io -o jsonpath='{.status.conditions[?(@.type=="Established")].status}' 2>/dev/null)
if [ "$S" = "True" ]; then echo "✅ Gateway API CRDs installed (gateways CRD Established)"; exit 0; fi
echo "❌ Gateway API CRDs not installed. Apply the staged manifest: kubectl apply -f /tmp/gateway-api-crds.yaml"; exit 1
