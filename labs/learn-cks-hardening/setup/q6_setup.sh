#!/bin/bash
# Step 6 (least-privilege RBAC): ensure ns + SA 'reader' exist; clear any prior
# Role/RoleBinding from an earlier attempt. RESOURCE-LEVEL cleanup — never delete the ns.
NS=cks-learn
kubectl get namespace "$NS" >/dev/null 2>&1 || kubectl create namespace "$NS" >/dev/null 2>&1
kubectl -n "$NS" get serviceaccount reader >/dev/null 2>&1 || kubectl -n "$NS" create serviceaccount reader >/dev/null 2>&1
kubectl -n "$NS" delete role pod-reader --ignore-not-found >/dev/null 2>&1
kubectl -n "$NS" delete rolebinding reader-pr --ignore-not-found >/dev/null 2>&1
echo "cks-learn ready with ServiceAccount 'reader' (grant it least-privilege pod read access)"
