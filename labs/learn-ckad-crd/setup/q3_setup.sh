#!/bin/bash
# Ensure the Gizmo CRD is present for step 3 (idempotent — q0 seeds it too, this is a safety net
# so the step works even if run in isolation). Does NOT create the CR; that is the learner's job.
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
kubectl get namespace crd-learn >/dev/null 2>&1 || kubectl create namespace crd-learn >/dev/null 2>&1
echo "seeded CRD gizmos.demo.example.com (discover it with: kubectl api-resources --api-group=demo.example.com)"
