#!/bin/bash
# RUNTIME step: live detection needs a BTF host (modern-ebpf probe) which this bench lacks.
# Grade the closest verifiable artifact: the 'Terminal shell in container' rule is present
# and NOT disabled (no 'enabled: false' attached to it, not commented out).
NS=falco
get_local() {
  kubectl -n "$NS" get configmap falco -o jsonpath='{.data.falco_rules\.local\.yaml}' 2>/dev/null
  kubectl -n "$NS" exec ds/falco -c falco -- cat /etc/falco/falco_rules.local.yaml 2>/dev/null
}
RULES=$(get_local)
if [ -z "$RULES" ]; then
  echo "❌ could not read falco_rules.local.yaml (ConfigMap key or pod file)"; exit 1
fi
# the rule must appear as an active '- rule:' entry (not a commented '# - rule:')
if ! echo "$RULES" | grep -E '^[[:space:]]*-[[:space:]]*rule:[[:space:]]*Terminal shell in container' >/dev/null 2>&1; then
  echo "❌ 'Terminal shell in container' is not an active rule (missing or commented out) in falco_rules.local.yaml"; exit 1
fi
# reject an explicit disable on that rule block
BLOCK=$(echo "$RULES" | awk '/-[[:space:]]*rule:[[:space:]]*Terminal shell in container/{f=1} f{print} /^[[:space:]]*-[[:space:]]*(rule|macro|list):/{if(f && $0 !~ /Terminal shell in container/){exit}}')
if echo "$BLOCK" | grep -Eq 'enabled:[[:space:]]*false'; then
  echo "❌ rule 'Terminal shell in container' is disabled (enabled: false). Re-enable it"; exit 1
fi
echo "✅ rule 'Terminal shell in container' is enabled (live detection requires a BTF host — verified via the enabled-rule artifact)"; exit 0
