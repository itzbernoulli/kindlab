#!/bin/bash
if ! kubectl get crd gizmos.demo.example.com >/dev/null 2>&1; then
  echo "❌ seeded CRD gizmos.demo.example.com is missing — re-run setup; discover it with: kubectl api-resources --api-group=demo.example.com"; exit 1
fi
if ! kubectl -n crd-learn get gizmo turbo >/dev/null 2>&1; then
  echo "❌ Gizmo 'turbo' not found in crd-learn — create a Gizmo (apiVersion demo.example.com/v1) named turbo with spec.power=9"; exit 1
fi
POWER=$(kubectl -n crd-learn get gizmo turbo -o jsonpath='{.spec.power}' 2>/dev/null)
if [ "$POWER" = "9" ]; then echo "✅ Gizmo 'turbo' exists in crd-learn with power=9 (used the seeded CRD)"; exit 0; fi
echo "❌ Gizmo 'turbo' spec.power wrong — need power=9 (got '${POWER}')"; exit 1
