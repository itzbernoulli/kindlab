#!/bin/bash
# The install must use the modern-eBPF driver. Helm renders this into the 'falco'
# ConfigMap (falco.yaml -> engine.kind: modern_ebpf). Fall back to the DaemonSet
# spec text. Accept either 'modern_ebpf' or 'modern-ebpf'.
NS=falco
CM=$(kubectl -n "$NS" get configmap falco -o jsonpath='{.data.falco\.yaml}' 2>/dev/null)
DSJSON=$(kubectl -n "$NS" get daemonset falco -o json 2>/dev/null)
HAYSTACK="$CM
$DSJSON"
if [ -z "$CM" ] && [ -z "$DSJSON" ]; then
  echo "❌ cannot read the Falco config (ConfigMap 'falco' falco.yaml or DaemonSet). Install Falco first"; exit 1
fi
if echo "$HAYSTACK" | grep -Eqi 'modern[_-]ebpf'; then
  echo "✅ Falco is configured with the modern-eBPF driver (modern_ebpf)"; exit 0
fi
FOUND=$(echo "$CM" | grep -Ei '^[[:space:]]*kind:' | head -1 | tr -d '\r')
echo "❌ modern-eBPF driver not detected (found engine '${FOUND:-unknown}'). Reinstall with --set driver.kind=modern-ebpf"; exit 1
