#!/bin/bash
if ! kubectl get pod sandboxed -n runtimeclass-learn >/dev/null 2>&1; then
  echo "❌ pod 'sandboxed' not found. Recreate it with gvisor + hardening."; exit 1
fi
RC=$(kubectl get pod sandboxed -n runtimeclass-learn -o jsonpath='{.spec.runtimeClassName}' 2>/dev/null)
NR=$(kubectl get pod sandboxed -n runtimeclass-learn -o jsonpath='{.spec.securityContext.runAsNonRoot}' 2>/dev/null)
DROP=$(kubectl get pod sandboxed -n runtimeclass-learn -o jsonpath='{.spec.containers[0].securityContext.capabilities.drop}' 2>/dev/null)
if [ "$RC" != "gvisor" ]; then echo "❌ 'sandboxed' must keep runtimeClassName=gvisor (got '${RC:-<empty>}')."; exit 1; fi
if [ "$NR" != "true" ]; then echo "❌ set spec.securityContext.runAsNonRoot: true (got '${NR:-<empty>}')."; exit 1; fi
if echo "$DROP" | grep -q "ALL"; then
  echo "✅ 'sandboxed' keeps gvisor, runs non-root, and drops ALL capabilities"; exit 0
fi
echo "❌ container must drop ALL capabilities (securityContext.capabilities.drop: [\"ALL\"]); got '${DROP:-<empty>}'."; exit 1
