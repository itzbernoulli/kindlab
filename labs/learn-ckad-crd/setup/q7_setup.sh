#!/bin/bash
# Seed a BROKEN Sprocket CRD for the step-7 diagnose-and-fix: its only version is served:false,
# so the REST endpoint is never exposed and `kubectl apply` of a Sprocket fails until the learner
# patches served:true. Idempotent (re-seeds the broken state each run).
NS=crd-learn
kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create namespace "$NS" >/dev/null 2>&1
# Recreate from scratch so a re-run always restores the broken (served:false) state.
kubectl delete crd sprockets.demo.example.com --ignore-not-found --wait=true >/dev/null 2>&1
cat <<'YAML' | kubectl apply -f - >/dev/null 2>&1
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: sprockets.demo.example.com
spec:
  group: demo.example.com
  scope: Namespaced
  names:
    kind: Sprocket
    plural: sprockets
    singular: sprocket
  versions:
  - name: v1
    served: false
    storage: true
    schema:
      openAPIV3Schema:
        type: object
        properties:
          spec:
            type: object
            properties:
              teeth:
                type: integer
YAML
echo "seeded BROKEN CRD sprockets.demo.example.com (v1 served:false — diagnose & fix in step 7)"
