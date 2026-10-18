#!/bin/bash
# Tuning: the local rules must include an exception named 'known_good' OR a tuning
# macro (referenced via 'and not'), and reference the known-good process 'my-healthcheck'.
NS=falco
get_local() {
  kubectl -n "$NS" get configmap falco -o jsonpath='{.data.falco_rules\.local\.yaml}' 2>/dev/null
  kubectl -n "$NS" exec ds/falco -c falco -- cat /etc/falco/falco_rules.local.yaml 2>/dev/null
}
RULES=$(get_local)
[ -z "$RULES" ] && { echo "❌ could not read falco_rules.local.yaml (ConfigMap 'falco' key or pod file)"; exit 1; }
if ! echo "$RULES" | grep -q 'my-healthcheck'; then
  echo "❌ no reference to the known-good process 'my-healthcheck' in falco_rules.local.yaml"; exit 1
fi
HAS_EXC=0; HAS_MACRO=0
echo "$RULES" | grep -Eq 'name:[[:space:]]*known_good' && HAS_EXC=1
echo "$RULES" | grep -Eq '^[[:space:]]*-[[:space:]]*macro:' && echo "$RULES" | grep -q 'and not' && HAS_MACRO=1
if [ "$HAS_EXC" -eq 1 ]; then
  echo "✅ exception 'known_good' referencing 'my-healthcheck' present in local rules"; exit 0
fi
if [ "$HAS_MACRO" -eq 1 ]; then
  echo "✅ tuning macro ('and not ...') referencing 'my-healthcheck' present in local rules"; exit 0
fi
echo "❌ 'my-healthcheck' found but no exception named 'known_good' and no tuning macro ('and not <macro>'). Add one"; exit 1
