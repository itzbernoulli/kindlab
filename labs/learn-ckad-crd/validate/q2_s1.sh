#!/bin/bash
if ! kubectl -n crd-learn get widget gadget >/dev/null 2>&1; then
  echo "❌ Widget 'gadget' not found in crd-learn — create a Widget (apiVersion stable.example.com/v1) named gadget"; exit 1
fi
SIZE=$(kubectl -n crd-learn get widget gadget -o jsonpath='{.spec.size}' 2>/dev/null)
COLOR=$(kubectl -n crd-learn get widget gadget -o jsonpath='{.spec.color}' 2>/dev/null)
if [ "$SIZE" = "3" ] && [ "$COLOR" = "blue" ]; then echo "✅ Widget 'gadget' exists in crd-learn with size=3 color=blue"; exit 0; fi
echo "❌ Widget 'gadget' spec values wrong — need spec.size=3 and spec.color=blue (got size='${SIZE}' color='${COLOR}')"; exit 1
