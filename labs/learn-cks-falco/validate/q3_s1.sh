#!/bin/bash
# The rule named 'Terminal shell in container' must exist AND its own block must
# reference spawned_process + shell_procs + container (scoped to the rule, not the whole file).
NS=falco
get_local() {
  kubectl -n "$NS" get configmap falco -o jsonpath='{.data.falco_rules\.local\.yaml}' 2>/dev/null
  kubectl -n "$NS" exec ds/falco -c falco -- cat /etc/falco/falco_rules.local.yaml 2>/dev/null
}
RULES=$(get_local)
[ -z "$RULES" ] && { echo "❌ could not read falco_rules.local.yaml (ConfigMap key or pod file)"; exit 1; }
# extract only the 'Terminal shell in container' rule block
BLOCK=$(echo "$RULES" | awk '/-[[:space:]]*rule:[[:space:]]*Terminal shell in container/{f=1} f{print} f&&/^[[:space:]]*-[[:space:]]*(rule|macro|list):/&&$0!~/Terminal shell in container/{exit}')
[ -z "$BLOCK" ] && { echo "❌ rule 'Terminal shell in container' not found in falco_rules.local.yaml"; exit 1; }
MISS=""
echo "$BLOCK" | grep -q 'spawned_process' || MISS="$MISS spawned_process"
echo "$BLOCK" | grep -q 'shell_procs'     || MISS="$MISS shell_procs"
echo "$BLOCK" | grep -q 'container'        || MISS="$MISS container"
if [ -n "$MISS" ]; then
  echo "❌ the 'Terminal shell in container' rule's condition is missing:$MISS (its condition must reference spawned_process, container, shell_procs)"; exit 1
fi
echo "✅ rule 'Terminal shell in container' has a condition referencing spawned_process + shell_procs + container"; exit 0
