#!/bin/bash
if ! kubectl get crd widgets.stable.example.com >/dev/null 2>&1; then
  echo "❌ CRD widgets.stable.example.com is missing — complete step 1 first"; exit 1
fi
if ! kubectl -n crd-learn get widget widget2 >/dev/null 2>&1; then
  echo "❌ second Widget 'widget2' not found — create another Widget named widget2 (spec.size=7, spec.color=red) in crd-learn"; exit 1
fi
COUNT=$(kubectl -n crd-learn get widgets --no-headers 2>/dev/null | grep -c .)
if [ "${COUNT:-0}" -ge 2 ]; then echo "✅ crd-learn has $COUNT Widgets including widget2 (listable via plural / shortName)"; exit 0; fi
echo "❌ expected at least 2 Widgets in crd-learn (got ${COUNT:-0}) — create widget2 alongside gadget"; exit 1
