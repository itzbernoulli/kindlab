#!/bin/bash
if ! kubectl get crd widgets.stable.example.com >/dev/null 2>&1; then
  echo "❌ CRD widgets.stable.example.com is gone — delete only the CR 'scratch', never the CRD itself"; exit 1
fi
if kubectl -n crd-learn get widget scratch >/dev/null 2>&1; then
  echo "❌ Widget 'scratch' still exists — delete it: kubectl -n crd-learn delete widget scratch"; exit 1
fi
for w in gadget widget2; do
  if ! kubectl -n crd-learn get widget "$w" >/dev/null 2>&1; then
    echo "❌ Widget '$w' is missing — deleting 'scratch' must not affect sibling CRs or the CRD (restore '$w' from the earlier step)"; exit 1
  fi
done
echo "✅ 'scratch' deleted while the CRD, gadget, and widget2 all survive — a CR's deletion never cascades to the CRD or its siblings"; exit 0
