#!/bin/bash
# Step 8 (diagnose & fix RBAC): ensure ns + SA 'audit-sa' exist, and (re)seed a BROKEN
# Role/RoleBinding — the Role grants get,list on 'services' instead of 'pods', so
# 'can-i list pods' is 'no' until the learner fixes the resource. RESOURCE-LEVEL only.
NS=cks-learn
kubectl get namespace "$NS" >/dev/null 2>&1 || kubectl create namespace "$NS" >/dev/null 2>&1
kubectl -n "$NS" get serviceaccount audit-sa >/dev/null 2>&1 || kubectl -n "$NS" create serviceaccount audit-sa >/dev/null 2>&1
# Force the Role back to the broken state even if a previous attempt fixed it.
kubectl -n "$NS" delete role audit-role --ignore-not-found >/dev/null 2>&1
kubectl -n "$NS" apply -f - >/dev/null 2>&1 <<'YAML'
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata: { name: audit-role, namespace: cks-learn }
rules:
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
# Ensure some pods exist so 'list pods' is meaningful once fixed.
kubectl -n "$NS" get pod demo >/dev/null 2>&1 || kubectl -n "$NS" run demo --image=busybox:1.36 --restart=Never --command -- sleep 3600 >/dev/null 2>&1
echo "seeded broken audit-role (grants get,list on 'services', not 'pods') for SA 'audit-sa' — diagnose & fix"
