#!/bin/bash
# Rule 'Terminal shell in container' must exist AND its own block must reference
# spawned_process + container + shell_procs, with priority WARNING. Scoped to the
# rule block (not the whole file) so stray matches elsewhere can't pass it.
NS=falco
get_local() {
  kubectl -n "$NS" get configmap falco -o jsonpath='{.data.falco_rules\.local\.yaml}' 2>/dev/null
  kubectl -n "$NS" exec ds/falco -c falco -- cat /etc/falco/falco_rules.local.yaml 2>/dev/null
}
RULES=$(get_local)
[ -z "$RULES" ] && { echo "❌ could not read falco_rules.local.yaml (ConfigMap 'falco' key or pod file)"; exit 1; }
BLOCK=$(echo "$RULES" | awk '/-[[:space:]]*rule:[[:space:]]*Terminal shell in container/{f=1} f{print} f&&/^[[:space:]]*-[[:space:]]*(rule|macro|list):/&&$0!~/Terminal shell in container/{exit}')
[ -z "$BLOCK" ] && { echo "❌ rule 'Terminal shell in container' not found in falco_rules.local.yaml"; exit 1; }
MISS=""
echo "$BLOCK" | grep -q 'spawned_process' || MISS="$MISS spawned_process"
echo "$BLOCK" | grep -q 'container'       || MISS="$MISS container"
echo "$BLOCK" | grep -q 'shell_procs'     || MISS="$MISS shell_procs"
if [ -n "$MISS" ]; then
  echo "❌ the 'Terminal shell in container' condition is missing:$MISS (it must reference spawned_process, container, shell_procs)"; exit 1
fi
if ! echo "$BLOCK" | grep -Eqi 'priority:[[:space:]]*WARNING'; then
  P=$(echo "$BLOCK" | grep -Ei 'priority:' | head -1 | tr -d '\r')
  echo "❌ rule priority must be WARNING (found '${P:-none}')"; exit 1
fi
echo "✅ rule 'Terminal shell in container' has condition spawned_process + container + shell_procs and priority WARNING"; exit 0
