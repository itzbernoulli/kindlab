#!/bin/bash
if ! kubectl get crd robots.demo.example.com >/dev/null 2>&1; then
  echo "❌ seeded CRD robots.demo.example.com is missing — re-run setup"; exit 1
fi
J=$(kubectl -n crd-learn get robot r2d2 -o json 2>/dev/null)
[ -z "$J" ] && { echo "❌ Robot 'r2d2' not found in crd-learn — create a Robot (demo.example.com/v1) with spec.model=astromech, spec.mode=turbo"; exit 1; }
export J
python3 - <<'PY'
import os,json,sys
r=json.loads(os.environ['J'])
def fail(m): print("❌ "+m); sys.exit(1)
if r.get("apiVersion")!="demo.example.com/v1": fail("apiVersion must be demo.example.com/v1 (got %r)"%r.get("apiVersion"))
if r.get("kind")!="Robot": fail("kind must be Robot (got %r)"%r.get("kind"))
spec=r.get("spec") or {}
if spec.get("model")!="astromech": fail("spec.model must be astromech (got %r)"%spec.get("model"))
if spec.get("mode")!="turbo": fail("spec.mode must be turbo (got %r)"%spec.get("mode"))
print("✅ Robot 'r2d2' in crd-learn with model=astromech, mode=turbo (passed required+enum validation)")
PY
