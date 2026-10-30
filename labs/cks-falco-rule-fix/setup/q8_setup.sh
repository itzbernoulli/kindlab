#!/bin/bash
# Prep for Step 8 (diagnose & fix). Seed a standalone ConfigMap 'falco-custom-rules'
# holding a BROKEN custom rule: the condition references an undefined macro
# 'spawned_proces' (typo) AND the rule carries 'enabled: false'. The learner must
# fix both. Resource-level + idempotent (never drops the whole namespace).
NS=falco

# Ensure the namespace exists (do NOT delete it).
kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create namespace "$NS" >/dev/null 2>&1

# Replace only this specific ConfigMap with the broken seed.
kubectl -n "$NS" delete configmap falco-custom-rules --ignore-not-found >/dev/null 2>&1
kubectl -n "$NS" apply -f - >/dev/null 2>&1 <<'YAML'
apiVersion: v1
kind: ConfigMap
metadata:
  name: falco-custom-rules
  namespace: falco
data:
  custom_rules.yaml: |
    # BROKEN on purpose (diagnose & fix):
    #  1) 'spawned_proces' is a typo for the real macro 'spawned_process'
    #     -> Falco rejects the file: "undefined macro 'spawned_proces'"
    #  2) 'enabled: false' silently disables the rule
    - rule: Detect package mgmt in container
      desc: A package manager ran inside a container
      condition: spawned_proces and container
      output: "package mgmt in container (cmd=%proc.cmdline container=%container.id)"
      priority: WARNING
      enabled: false
YAML
echo "learn-cks-falco Step 8 ready: broken ConfigMap 'falco-custom-rules' seeded in '$NS' (undefined-macro typo + enabled:false — diagnose & fix)"
