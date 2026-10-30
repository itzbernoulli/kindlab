#!/bin/bash
# Reset the learn-cks-hardening environment to a clean, idempotent slate.
# NODE-LEVEL lab: namespace cleanup is RESOURCE-LEVEL — NEVER delete the namespace
# (that races under load and wipes the lab). Ensure the ns exists, then delete the
# specific objects this lab creates and re-seed fixtures.

NS=cks-learn
kubectl get namespace "$NS" >/dev/null 2>&1 || kubectl create namespace "$NS" >/dev/null 2>&1

# ---- RBAC steps 6 & 8: clear prior attempts (resource-level), re-seed SAs + pods ----
kubectl -n "$NS" delete role pod-reader audit-role --ignore-not-found >/dev/null 2>&1
kubectl -n "$NS" delete rolebinding reader-pr audit-rb --ignore-not-found >/dev/null 2>&1
kubectl -n "$NS" delete pod hardened demo --ignore-not-found --force --grace-period=0 >/dev/null 2>&1
kubectl -n "$NS" delete serviceaccount no-token --ignore-not-found >/dev/null 2>&1

# Step 6 fixture: ServiceAccount 'reader' (learner grants it least-privilege pod read).
kubectl -n "$NS" get serviceaccount reader >/dev/null 2>&1 || kubectl -n "$NS" create serviceaccount reader >/dev/null 2>&1
# Step 8 fixture: ServiceAccount 'audit-sa' + a BROKEN Role/RoleBinding (wrong resource).
kubectl -n "$NS" get serviceaccount audit-sa >/dev/null 2>&1 || kubectl -n "$NS" create serviceaccount audit-sa >/dev/null 2>&1
kubectl -n "$NS" apply -f - >/dev/null 2>&1 <<'YAML'
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata: { name: audit-role, namespace: cks-learn }
rules:
# BROKEN on purpose: grants get,list on 'services', not 'pods' -> can-i list pods == no
- apiGroups: [""]
  resources: ["services"]
  verbs: ["get","list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata: { name: audit-rb, namespace: cks-learn }
roleRef: { apiGroup: rbac.authorization.k8s.io, kind: Role, name: audit-role }
subjects:
- kind: ServiceAccount
  name: audit-sa
  namespace: cks-learn
YAML

# A couple of pods so 'list pods' has something real to show.
kubectl -n "$NS" run demo --image=busybox:1.36 --restart=Never --command -- sleep 3600 >/dev/null 2>&1

echo "cks-learn ready: SA 'reader' (step 6), SA 'audit-sa' + broken audit-role (step 8). Namespace preserved."
