#!/bin/bash
# Diagnose-and-fix seed: a CORRECT Role 'secret-reader' plus a RoleBinding
# 'auditor-sr' whose roleRef points at a NON-EXISTENT Role name (typo
# 'secret-readr'), so the binding grants nothing. Learner must repoint it.
NS=rbac-learn
kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create namespace "$NS" >/dev/null 2>&1

# Clean any prior attempt so re-runs start from the broken state.
kubectl -n "$NS" delete rolebinding auditor-sr --ignore-not-found >/dev/null 2>&1
kubectl -n "$NS" delete role secret-reader --ignore-not-found >/dev/null 2>&1

# The real, correctly-ruled Role.
kubectl -n "$NS" create role secret-reader --verb=get,list --resource=secrets >/dev/null 2>&1

# Broken binding: roleRef names a Role that does not exist.
cat <<'YAML' | kubectl apply -f - >/dev/null 2>&1
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: auditor-sr
  namespace: rbac-learn
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: secret-readr
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: auditor
YAML
echo "seeded broken RoleBinding 'auditor-sr' (dangling roleRef -> Role 'secret-readr'); diagnose & fix in step 8"
