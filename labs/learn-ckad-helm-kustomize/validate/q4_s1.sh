#!/bin/bash
DEP=$(kubectl get deploy hello -n kustomize-learn -o name 2>/dev/null)
if [ -n "$DEP" ]; then
  echo "✅ Deployment 'hello' created in kustomize-learn from the base"; exit 0
fi
echo "❌ Deployment 'hello' not found in kustomize-learn — apply the base: kubectl apply -k /tmp/kustomize-ckad"; exit 1
