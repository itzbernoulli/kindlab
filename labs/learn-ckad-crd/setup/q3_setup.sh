#!/bin/bash
# Seed the Gizmo CRD the learner must DISCOVER in step 3 (idempotent). Does NOT create any CR.
NS=crd-learn
kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create namespace "$NS" >/dev/null 2>&1
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
echo "seeded CRD gizmos.demo.example.com (discover: kubectl api-resources --api-group=demo.example.com)"
