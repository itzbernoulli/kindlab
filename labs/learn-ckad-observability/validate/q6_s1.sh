#!/bin/bash
kubectl -n ckad-observability get pod blackbox >/dev/null 2>&1 || { echo "❌ pod 'blackbox' not found"; exit 1; }
IMG=$(kubectl -n ckad-observability get pod blackbox -o jsonpath='{.spec.ephemeralContainers[*].image}' 2>/dev/null)
echo "$IMG" | grep -q 'busybox' || { echo "❌ no ephemeral debug container on 'blackbox' — add one with: kubectl debug blackbox -n ckad-observability --image=busybox:1.36 --target=app"; exit 1; }
echo "✅ blackbox has an ephemeral debug container ($IMG)"; exit 0
