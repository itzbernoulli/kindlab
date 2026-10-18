#!/bin/bash
# Seed a BROKEN Service 'api' whose selector does not match the api pods (app=api),
# so it has no endpoints. The learner's job in step 5 is to fix the selector.
# Idempotent: recreate the Service with the wrong selector every time.
kubectl -n svcnet-learn delete svc api --ignore-not-found >/dev/null 2>&1
cat <<'YAML' | kubectl apply -f - >/dev/null 2>&1
apiVersion: v1
kind: Service
metadata:
  name: api
  namespace: svcnet-learn
spec:
  type: ClusterIP
  selector:
    app: api-WRONG
  ports:
  - port: 80
    targetPort: 8080
YAML
echo "seeded broken Service 'api' (selector app=api-WRONG -> no endpoints)"
