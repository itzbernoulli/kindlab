#!/bin/bash
# The two pods must DIFFER: 'confined' uses k8s-deny-write; 'unconfined' does not.
NS=cks-apparmor

prof() {  # prints the effective localhost profile name for a pod, or "" if none
  local pod=$1
  local t lp a
  t=$(kubectl -n "$NS" get pod "$pod" -o jsonpath='{.spec.containers[0].securityContext.appArmorProfile.type}' 2>/dev/null)
  lp=$(kubectl -n "$NS" get pod "$pod" -o jsonpath='{.spec.containers[0].securityContext.appArmorProfile.localhostProfile}' 2>/dev/null)
  a=$(kubectl -n "$NS" get pod "$pod" -o jsonpath='{.metadata.annotations.container\.apparmor\.security\.beta\.kubernetes\.io/hello}' 2>/dev/null)
  if [ "$t" = "Localhost" ] && [ -n "$lp" ]; then echo "$lp"; return; fi
  case "$a" in localhost/*) echo "${a#localhost/}";; esac
}

if ! kubectl -n "$NS" get pod unconfined >/dev/null 2>&1; then
  echo "❌ pod 'unconfined' not found in $NS. Create it on $W1 with NO AppArmor localhost profile."; exit 1
fi

C=$(prof confined)
U=$(prof unconfined)

if [ "$C" != "k8s-deny-write" ]; then
  echo "❌ 'confined' no longer uses k8s-deny-write (got '${C:-none}'). Keep the Step 2 pod intact."; exit 1
fi
if [ "$U" = "k8s-deny-write" ]; then
  echo "❌ 'unconfined' also references k8s-deny-write — the pods must differ. Leave its AppArmor profile unset (or type Unconfined)."; exit 1
fi
echo "✅ confined uses k8s-deny-write; unconfined uses '${U:-none}' — the two pods differ as intended"; exit 0
