#!/bin/bash
S=$(kubectl get pod sandboxed -n runtimeclass-learn -o jsonpath='{.spec.runtimeClassName}' 2>/dev/null)
if ! kubectl get pod normal -n runtimeclass-learn >/dev/null 2>&1; then
  echo "❌ pod 'normal' not found. Create a busybox:1.36 sleep pod with NO runtimeClassName (default runtime)."; exit 1
fi
N=$(kubectl get pod normal -n runtimeclass-learn -o jsonpath='{.spec.runtimeClassName}' 2>/dev/null)
if [ "$S" = "gvisor" ] && [ -z "$N" ]; then
  echo "✅ 'sandboxed' uses gvisor; 'normal' uses the default runtime (they differ)"; exit 0
fi
if [ "$S" != "gvisor" ]; then echo "❌ 'sandboxed' must keep runtimeClassName=gvisor (got '${S:-<empty>}')."; exit 1; fi
echo "❌ 'normal' must have NO runtimeClassName (got '${N}'). Leave spec.runtimeClassName unset."; exit 1
