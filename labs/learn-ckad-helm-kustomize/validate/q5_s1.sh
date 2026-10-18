#!/bin/bash
DEP=$(kubectl get deploy prod-hello -n kustomize-learn -o name 2>/dev/null)
if [ -n "$DEP" ]; then
  echo "✅ namePrefix overlay produced Deployment 'prod-hello' in kustomize-learn"; exit 0
fi
echo "❌ Deployment 'prod-hello' not found in kustomize-learn — add 'namePrefix: prod-' to /tmp/kustomize-ckad/kustomization.yaml and re-run: kubectl apply -k /tmp/kustomize-ckad"; exit 1
