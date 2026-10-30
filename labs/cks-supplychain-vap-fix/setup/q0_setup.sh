#!/bin/bash
# Prepare cks-supply with RESOURCE-LEVEL cleanup (never `delete namespace` — it races
# under load and wipes the lab). Ensure the ns, clear the objects this lab builds,
# seed the kubesec manifest ConfigMap, and seed the step-8 diagnose-and-fix (a
# ValidatingAdmissionPolicyBinding that enforces nothing).
NS=cks-supply
kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create namespace "$NS" >/dev/null 2>&1

# Namespaced objects the learner creates.
kubectl -n "$NS" delete job trivy-scan kubesec-scan --ignore-not-found >/dev/null 2>&1
kubectl -n "$NS" delete pod digest-pod private-pod --ignore-not-found --force --grace-period=0 >/dev/null 2>&1
kubectl -n "$NS" delete deployment web --ignore-not-found >/dev/null 2>&1
kubectl -n "$NS" delete secret regcred --ignore-not-found >/dev/null 2>&1

# Cluster-scoped admission objects the learner creates (steps 5 & 6).
kubectl delete validatingadmissionpolicybinding approved-registry-binding no-latest-tag-binding --ignore-not-found >/dev/null 2>&1
kubectl delete validatingadmissionpolicy approved-registry no-latest-tag --ignore-not-found >/dev/null 2>&1

# Seed the manifest ConfigMap used by the kubesec step.
cat <<'YAML' >/tmp/kubesec-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: sample
spec:
  containers:
  - name: app
    image: nginx:1.25-alpine
YAML
kubectl -n "$NS" delete configmap kubesec-manifest --ignore-not-found >/dev/null 2>&1
kubectl -n "$NS" create configmap kubesec-manifest --from-file=pod.yaml=/tmp/kubesec-pod.yaml >/dev/null 2>&1

# Step-8 diagnose-and-fix: a real policy 'block-privileged', but a BROKEN binding that
# names a wrong policy and uses action Warn -> it enforces nothing.
kubectl delete validatingadmissionpolicybinding block-privileged-binding --ignore-not-found >/dev/null 2>&1
kubectl delete validatingadmissionpolicy block-privileged --ignore-not-found >/dev/null 2>&1
kubectl apply -f - >/dev/null 2>&1 <<'YAML'
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionPolicy
metadata:
  name: block-privileged
spec:
  failurePolicy: Fail
  matchConstraints:
    resourceRules:
    - apiGroups: [""]
      apiVersions: ["v1"]
      operations: ["CREATE","UPDATE"]
      resources: ["pods"]
  validations:
  - expression: "object.spec.containers.all(c, !has(c.securityContext) || c.securityContext.privileged != true)"
    message: "privileged containers are banned"
---
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionPolicyBinding
metadata:
  name: block-privileged-binding
spec:
  policyName: block-privilege
  validationActions: ["Warn"]
  matchResources: {}
YAML

echo "cks-supply ready: kubesec-manifest seeded; broken binding 'block-privileged-binding' seeded (enforces nothing — diagnose & fix in step 8)"
