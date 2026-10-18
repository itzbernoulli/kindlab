#!/bin/bash
POD="cp-web-$CP"
PHASE=$(kubectl get pod "$POD" -n default -o jsonpath='{.status.phase}' 2>/dev/null)
if [ "$PHASE" = "Running" ]; then echo "✅ mirror pod $POD is Running"; exit 0; fi
echo "❌ mirror pod '$POD' phase='${PHASE:-not found}' (expected Running). Place a static pod named 'cp-web' (nginx:alpine) in /etc/kubernetes/manifests/ on $CP; static pods appear as <name>-<node>."; exit 1
