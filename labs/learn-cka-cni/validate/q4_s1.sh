#!/bin/bash
EP=$(kubectl get endpoints web -n cni-learn -o jsonpath='{.subsets[0].addresses[0].ip}' 2>/dev/null)
if [ -n "$EP" ]; then echo "✅ Service 'web' has active endpoints (e.g. $EP)"; exit 0; fi
echo "❌ Service 'web' has no endpoints — expose the web deployment: kubectl expose deployment web -n cni-learn --name=web --port=80"; exit 1
