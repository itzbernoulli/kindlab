#!/bin/bash
# Prepare rbac-learn WITHOUT deleting the namespace (that races under load).
# Ensure the ns exists, then do resource-level cleanup of everything this lab
# creates (both namespaced and cluster-scoped), and re-seed the two ConfigMaps.
NS=rbac-learn
kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create namespace "$NS" >/dev/null 2>&1

# Namespaced objects this lab builds (learner-created + any leftovers).
kubectl -n "$NS" delete role pod-reader cm-reader log-reader secret-reader --ignore-not-found >/dev/null 2>&1
kubectl -n "$NS" delete rolebinding dev-pr ci-pr dev-deploy dev-cm dev-log auditor-sr --ignore-not-found >/dev/null 2>&1
kubectl -n "$NS" delete serviceaccount ci --ignore-not-found >/dev/null 2>&1

# Cluster-scoped objects this lab builds.
kubectl delete clusterrole node-reader deploy-admin --ignore-not-found >/dev/null 2>&1
kubectl delete clusterrolebinding dev-nr --ignore-not-found >/dev/null 2>&1

# Re-seed the two ConfigMaps used by the resourceNames step.
kubectl -n "$NS" delete configmap app-config other-config --ignore-not-found >/dev/null 2>&1
kubectl -n "$NS" create configmap app-config   --from-literal=k=v >/dev/null 2>&1
kubectl -n "$NS" create configmap other-config --from-literal=k=v >/dev/null 2>&1

echo "rbac-learn ready (configmaps app-config, other-config seeded; lab objects cleaned)"
