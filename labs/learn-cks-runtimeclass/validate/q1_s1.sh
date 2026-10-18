#!/bin/bash
H=$(kubectl get runtimeclass gvisor -o jsonpath='{.handler}' 2>/dev/null)
[ "$H" = "runsc" ] && { echo "✅ RuntimeClass 'gvisor' exists with handler 'runsc'"; exit 0; }
if [ -z "$H" ]; then echo "❌ RuntimeClass 'gvisor' not found. Create it (apiVersion node.k8s.io/v1, top-level handler: runsc)."; exit 1; fi
echo "❌ RuntimeClass 'gvisor' has handler '$H', expected 'runsc'."; exit 1
