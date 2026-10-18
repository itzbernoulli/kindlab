#!/bin/bash
# Reset the learn environment to a clean slate: drop any Widget/Gizmo CRDs (and their CRs
# are garbage-collected with them), recreate the namespace, and seed the Gizmo CRD the lab
# asks the learner to DISCOVER in step 3. Idempotent.
kubectl delete crd widgets.stable.example.com --ignore-not-found --wait=true >/dev/null 2>&1
kubectl delete crd gizmos.demo.example.com --ignore-not-found --wait=true >/dev/null 2>&1
kubectl delete namespace crd-learn --ignore-not-found --wait=false >/dev/null 2>&1
for i in $(seq 1 30); do kubectl get ns crd-learn >/dev/null 2>&1 || break; sleep 1; done
kubectl create namespace crd-learn >/dev/null 2>&1

# Seed the Gizmo CRD (prerequisite for step 3 — learner only creates a CR for it).
cat <<'YAML' | kubectl apply -f - >/dev/null 2>&1
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: gizmos.demo.example.com
spec:
  group: demo.example.com
  scope: Namespaced
  names:
    kind: Gizmo
    plural: gizmos
    singular: gizmo
    shortNames: [gz]
  versions:
  - name: v1
    served: true
    storage: true
    schema:
      openAPIV3Schema:
        type: object
        properties:
          spec:
            type: object
            properties:
              power:
                type: integer
YAML
kubectl wait --for=condition=Established crd/gizmos.demo.example.com --timeout=30s >/dev/null 2>&1
echo "crd-learn ready (seeded CRD gizmos.demo.example.com for discovery in step 3)"
