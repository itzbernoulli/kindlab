#!/bin/bash
# Pod must reference a Localhost seccomp profile pointing at profiles/audit.json
# (either at pod-level securityContext or on the container).
T=$(kubectl get pod seccomp-audit -n default -o jsonpath='{.spec.securityContext.seccompProfile.type}{" "}{.spec.containers[0].securityContext.seccompProfile.type}' 2>/dev/null)
LP=$(kubectl get pod seccomp-audit -n default -o jsonpath='{.spec.securityContext.seccompProfile.localhostProfile}{" "}{.spec.containers[0].securityContext.seccompProfile.localhostProfile}' 2>/dev/null)
if echo "$T" | grep -q "Localhost" && echo "$LP" | grep -q "profiles/audit.json"; then
  echo "✅ pod seccomp-audit uses Localhost profile 'profiles/audit.json'"; exit 0
fi
echo "❌ pod seccomp-audit missing Localhost seccompProfile (type='${T:-none}', localhostProfile='${LP:-none}'; expected type Localhost + localhostProfile profiles/audit.json)"; exit 1
