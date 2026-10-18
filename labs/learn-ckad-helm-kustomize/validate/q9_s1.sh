#!/bin/bash
# Step 9: broken kustomization fixed => Deployment 'api' built and applied into kustomize-learn.
DEP=$(kubectl get deploy api -n kustomize-learn -o name 2>/dev/null)
if [ -n "$DEP" ]; then
  echo "✅ Deployment 'api' applied in kustomize-learn — the broken kustomization now builds"; exit 0
fi
echo "❌ Deployment 'api' not found in kustomize-learn — the kustomization at /tmp/kustomize-broken still won't build. Run 'kubectl kustomize /tmp/kustomize-broken' to see the error (resources points at a missing file), fix it, then kubectl apply -k /tmp/kustomize-broken"; exit 1
