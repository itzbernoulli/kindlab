#!/bin/bash
NS=cks-supply
D=web
kubectl -n "$NS" get deploy "$D" >/dev/null 2>&1 || { echo "❌ Deployment $D not found in $NS. Create it with a pinned image (e.g. nginx:1.25-alpine)."; exit 1; }
IMG=$(kubectl -n "$NS" get deploy "$D" -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)
[ -n "$IMG" ] || { echo "❌ could not read Deployment $D image."; exit 1; }
# reject :latest explicitly
echo "$IMG" | grep -q ':latest$' && { echo "❌ image '$IMG' uses :latest. Pin an explicit version or @sha256 digest."; exit 1; }
# accept if digest-pinned
if echo "$IMG" | grep -q '@sha256:'; then
  echo "✅ Deployment web uses a digest-pinned image ($IMG)"
  exit 0
fi
# otherwise require an explicit tag on the final path segment
NAME=${IMG##*/}
echo "$NAME" | grep -q ':' || { echo "❌ image '$IMG' has no explicit tag (implicit :latest). Pin a version like nginx:1.25-alpine."; exit 1; }
echo "✅ Deployment web uses a pinned version, not :latest ($IMG)"
exit 0
