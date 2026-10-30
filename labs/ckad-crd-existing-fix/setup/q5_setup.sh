#!/bin/bash
# Seed the Robot CRD with a REQUIRED field (spec.model) and an ENUM (spec.mode in eco|turbo)
# for step 5's schema-validation drill (idempotent). Does NOT create any CR.
NS=crd-learn
kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create namespace "$NS" >/dev/null 2>&1
cat <<'YAML' | kubectl apply -f - >/dev/null 2>&1
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: robots.demo.example.com
spec:
  group: demo.example.com
  scope: Namespaced
  names:
    kind: Robot
    plural: robots
    singular: robot
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
            required: [model]
            properties:
              model:
                type: string
              mode:
                type: string
                enum: [eco, turbo]
YAML
kubectl wait --for=condition=Established crd/robots.demo.example.com --timeout=30s >/dev/null 2>&1
echo "seeded CRD robots.demo.example.com (spec.model required; spec.mode enum eco|turbo)"
