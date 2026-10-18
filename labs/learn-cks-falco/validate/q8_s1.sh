#!/bin/bash
# Diagnose & fix: ConfigMap 'falco-custom-rules' key custom_rules.yaml held a rule
# 'Detect package mgmt in container' broken two ways — an undefined-macro typo
# ('spawned_proces') and 'enabled: false'. The fixed end-state must use the real
# macro 'spawned_process' and no longer disable the rule.
NS=falco
J=$(kubectl -n "$NS" get configmap falco-custom-rules -o json 2>/dev/null)
[ -z "$J" ] && { echo "❌ ConfigMap 'falco-custom-rules' not found in namespace '$NS' (don't delete it — fix it)"; exit 1; }
export J
python3 - <<'PY'
import os,json,sys,re
def fail(m): print("❌ "+m); sys.exit(1)
cm=json.loads(os.environ['J'])
data=cm.get("data") or {}
y=data.get("custom_rules.yaml")
if y is None: fail("key 'custom_rules.yaml' missing from ConfigMap falco-custom-rules (don't remove it)")

# Isolate the rule block so stray text elsewhere can't fool the check.
lines=y.splitlines()
block=[]; f=False
for ln in lines:
    if re.match(r'\s*-\s*rule:\s*Detect package mgmt in container', ln):
        f=True; block.append(ln); continue
    if f and re.match(r'\s*-\s*(rule|macro|list):', ln) and 'Detect package mgmt in container' not in ln:
        break
    if f: block.append(ln)
if not block: fail("rule 'Detect package mgmt in container' not found (don't remove it — fix it)")
b="\n".join(block)

# 1) typo must be gone and the real macro present in the condition.
if re.search(r'\bspawned_proces\b', b):
    fail("the undefined macro typo 'spawned_proces' is still present — fix it to 'spawned_process'")
if not re.search(r'\bspawned_process\b', b):
    fail("the rule condition must reference the real macro 'spawned_process'")

# 2) the rule must not be disabled.
if re.search(r'enabled:\s*false', b):
    fail("the rule still has 'enabled: false' — re-enable it (remove it or set enabled: true)")

print("✅ broken rule fixed: condition uses 'spawned_process' (typo gone) and the rule is enabled")
PY
