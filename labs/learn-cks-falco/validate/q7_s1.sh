#!/bin/bash
# The 'Terminal shell in container' rule must be an ACTIVE '- rule:' entry (not
# commented out) and must NOT carry 'enabled: false' on its block.
NS=falco
get_local() {
  kubectl -n "$NS" get configmap falco -o jsonpath='{.data.falco_rules\.local\.yaml}' 2>/dev/null
  kubectl -n "$NS" exec ds/falco -c falco -- cat /etc/falco/falco_rules.local.yaml 2>/dev/null
}
RULES=$(get_local)
[ -z "$RULES" ] && { echo "❌ could not read falco_rules.local.yaml (ConfigMap 'falco' key or pod file)"; exit 1; }
if ! echo "$RULES" | grep -E '^[[:space:]]*-[[:space:]]*rule:[[:space:]]*Terminal shell in container' >/dev/null 2>&1; then
  echo "❌ 'Terminal shell in container' is not an active '- rule:' (missing or commented out) in falco_rules.local.yaml"; exit 1
fi
BLOCK=$(echo "$RULES" | awk '/-[[:space:]]*rule:[[:space:]]*Terminal shell in container/{f=1} f{print} f&&/^[[:space:]]*-[[:space:]]*(rule|macro|list):/&&$0!~/Terminal shell in container/{exit}')
if echo "$BLOCK" | grep -Eq 'enabled:[[:space:]]*false'; then
  echo "❌ rule 'Terminal shell in container' is disabled (enabled: false). Re-enable it"; exit 1
fi
echo "✅ rule 'Terminal shell in container' is an active, enabled rule"; exit 0
