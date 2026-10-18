#!/bin/bash
if ! kubectl get pod sandboxed -n runtimeclass-learn >/dev/null 2>&1; then
  echo "❌ pod 'sandboxed' not found in runtimeclass-learn. Create a busybox:1.36 sleep pod with spec.runtimeClassName: gvisor."; exit 1
fi
RC=$(kubectl get pod sandboxed -n runtimeclass-learn -o jsonpath='{.spec.runtimeClassName}' 2>/dev/null)
[ "$RC" = "gvisor" ] && { echo "✅ pod 'sandboxed' requests runtimeClassName 'gvisor'"; exit 0; }
echo "❌ pod 'sandboxed' has runtimeClassName='${RC:-<empty>}', expected 'gvisor'. Set spec.runtimeClassName: gvisor."; exit 1
