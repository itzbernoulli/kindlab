#!/bin/bash
# Must define a list 'sensitive_dirs' containing /etc and /root, AND a macro
# 'write_sensitive_dir' whose condition references the list by name.
NS=falco
get_local() {
  kubectl -n "$NS" get configmap falco -o jsonpath='{.data.falco_rules\.local\.yaml}' 2>/dev/null
  kubectl -n "$NS" exec ds/falco -c falco -- cat /etc/falco/falco_rules.local.yaml 2>/dev/null
}
RULES=$(get_local)
[ -z "$RULES" ] && { echo "❌ could not read falco_rules.local.yaml (ConfigMap 'falco' key or pod file)"; exit 1; }

# list block
LBLOCK=$(echo "$RULES" | awk '/-[[:space:]]*list:[[:space:]]*sensitive_dirs([[:space:]]|$)/{f=1} f{print} f&&/^[[:space:]]*-[[:space:]]*(rule|macro|list):/&&$0!~/list:[[:space:]]*sensitive_dirs/{exit}')
[ -z "$LBLOCK" ] && { echo "❌ list 'sensitive_dirs' not found"; exit 1; }
MISS=""
echo "$LBLOCK" | grep -q '/etc'  || MISS="$MISS /etc"
echo "$LBLOCK" | grep -q '/root' || MISS="$MISS /root"
if [ -n "$MISS" ]; then
  echo "❌ list 'sensitive_dirs' is missing item(s):$MISS (items must include /etc and /root)"; exit 1
fi

# macro block referencing the list
MBLOCK=$(echo "$RULES" | awk '/-[[:space:]]*macro:[[:space:]]*write_sensitive_dir([[:space:]]|$)/{f=1} f{print} f&&/^[[:space:]]*-[[:space:]]*(rule|macro|list):/&&$0!~/macro:[[:space:]]*write_sensitive_dir/{exit}')
[ -z "$MBLOCK" ] && { echo "❌ macro 'write_sensitive_dir' not found"; exit 1; }
if ! echo "$MBLOCK" | grep -q 'sensitive_dirs'; then
  echo "❌ macro 'write_sensitive_dir' does not reference the list 'sensitive_dirs'"; exit 1
fi
echo "✅ list 'sensitive_dirs' (/etc,/root) + macro 'write_sensitive_dir' referencing it are present"; exit 0
