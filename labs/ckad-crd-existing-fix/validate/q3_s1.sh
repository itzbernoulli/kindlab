#!/bin/bash
if ! kubectl get crd gizmos.demo.example.com >/dev/null 2>&1; then
  echo "❌ seeded CRD gizmos.demo.example.com is missing — re-run setup; discover with: kubectl api-resources --api-group=demo.example.com"; exit 1
fi
J=$(kubectl -n crd-learn get gizmo turbo -o json 2>/dev/null)
[ -z "$J" ] && { echo "❌ Gizmo 'turbo' not found in crd-learn — create a Gizmo (apiVersion demo.example.com/v1) named turbo with spec.power=9"; exit 1; }
export J
python3 - <<'PY'
import os,json,sys
g=json.loads(os.environ['J'])
def fail(m): print("❌ "+m); sys.exit(1)
if g.get("apiVersion")!="demo.example.com/v1": fail("apiVersion must be demo.example.com/v1 (got %r)"%g.get("apiVersion"))
if g.get("kind")!="Gizmo": fail("kind must be Gizmo (got %r)"%g.get("kind"))
if (g.get("spec") or {}).get("power")!=9: fail("spec.power must be 9 (got %r)"%(g.get("spec") or {}).get("power"))
print("✅ Gizmo 'turbo' in crd-learn with power=9 (used the discovered CRD)")
PY
