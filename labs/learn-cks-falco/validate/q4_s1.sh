#!/bin/bash
# The 'Terminal shell in container' rule's output must carry context:
# %user.name, %container.id and %proc.cmdline (checked on the rule block).
NS=falco
get_local() {
  kubectl -n "$NS" get configmap falco -o jsonpath='{.data.falco_rules\.local\.yaml}' 2>/dev/null
  kubectl -n "$NS" exec ds/falco -c falco -- cat /etc/falco/falco_rules.local.yaml 2>/dev/null
}
RULES=$(get_local)
[ -z "$RULES" ] && { echo "❌ could not read falco_rules.local.yaml (ConfigMap 'falco' key or pod file)"; exit 1; }
BLOCK=$(echo "$RULES" | awk '/-[[:space:]]*rule:[[:space:]]*Terminal shell in container/{f=1} f{print} f&&/^[[:space:]]*-[[:space:]]*(rule|macro|list):/&&$0!~/Terminal shell in container/{exit}')
[ -z "$BLOCK" ] && { echo "❌ rule 'Terminal shell in container' not found (do Step 3 first)"; exit 1; }
OUT=$(echo "$BLOCK" | grep -E 'output:' )
[ -z "$OUT" ] && { echo "❌ the rule has no 'output:' line"; exit 1; }
MISS=""
echo "$BLOCK" | grep -q '%user.name'    || MISS="$MISS %user.name"
echo "$BLOCK" | grep -q '%container.id'  || MISS="$MISS %container.id"
echo "$BLOCK" | grep -q '%proc.cmdline'  || MISS="$MISS %proc.cmdline"
if [ -n "$MISS" ]; then
  echo "❌ the rule's output is missing field(s):$MISS (output must reference %user.name, %container.id, %proc.cmdline)"; exit 1
fi
echo "✅ output references %user.name, %container.id and %proc.cmdline"; exit 0
