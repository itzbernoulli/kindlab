#!/bin/bash
# readOnlyRootFilesystem true on the container + an emptyDir mounted at /tmp.
RO=$(kubectl get pod readonly-root -n default -o jsonpath='{.spec.containers[0].securityContext.readOnlyRootFilesystem}' 2>/dev/null)
MP=$(kubectl get pod readonly-root -n default -o jsonpath='{.spec.containers[0].volumeMounts[?(@.mountPath=="/tmp")].name}' 2>/dev/null)
ED=$(kubectl get pod readonly-root -n default -o jsonpath="{.spec.volumes[?(@.name=='$MP')].emptyDir}" 2>/dev/null)
if [ "$RO" = "true" ] && [ -n "$MP" ] && [ -n "$ED" ]; then
  echo "✅ readonly-root: readOnlyRootFilesystem=true with emptyDir volume '$MP' mounted at /tmp"; exit 0
fi
echo "❌ readonly-root wrong (readOnlyRootFilesystem='${RO:-none}', /tmp mount vol='${MP:-none}', emptyDir='${ED:-none}'; need readOnlyRootFilesystem true + emptyDir at /tmp)"; exit 1
