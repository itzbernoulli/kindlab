#!/bin/bash
# Pod 'confined' must be on $W1 and request localhost profile k8s-deny-write
# via either the typed appArmorProfile field or the beta annotation.
NS=cks-apparmor
NODE=$(kubectl -n "$NS" get pod confined -o jsonpath='{.spec.nodeName}' 2>/dev/null)
if [ -z "$NODE" ]; then
  echo "❌ pod 'confined' not found in $NS. Create it pinned to $W1."; exit 1
fi
if [ "$NODE" != "$W1" ]; then
  echo "❌ pod 'confined' is on '$NODE' (expected $W1). Set spec.nodeName: $W1."; exit 1
fi

# Typed field (1.30+): type Localhost + localhostProfile k8s-deny-write
TYPE=$(kubectl -n "$NS" get pod confined -o jsonpath='{.spec.containers[0].securityContext.appArmorProfile.type}' 2>/dev/null)
LP=$(kubectl -n "$NS" get pod confined -o jsonpath='{.spec.containers[0].securityContext.appArmorProfile.localhostProfile}' 2>/dev/null)
if [ "$TYPE" = "Localhost" ] && [ "$LP" = "k8s-deny-write" ]; then
  echo "✅ pod 'confined' on $W1 uses localhost AppArmor profile k8s-deny-write"; exit 0
fi

# Beta annotation fallback: container.apparmor.security.beta.kubernetes.io/hello=localhost/k8s-deny-write
ANN=$(kubectl -n "$NS" get pod confined -o jsonpath='{.metadata.annotations.container\.apparmor\.security\.beta\.kubernetes\.io/hello}' 2>/dev/null)
if [ "$ANN" = "localhost/k8s-deny-write" ]; then
  echo "✅ pod 'confined' on $W1 uses localhost AppArmor profile k8s-deny-write (via annotation)"; exit 0
fi

echo "❌ pod 'confined' does not request localhost/k8s-deny-write (type='${TYPE:-none}', localhostProfile='${LP:-none}', annotation='${ANN:-none}')."; exit 1
