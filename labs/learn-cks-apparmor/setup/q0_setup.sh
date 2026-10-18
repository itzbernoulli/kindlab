#!/bin/bash
# Reset the AppArmor learn environment to a clean slate (idempotent).
# Safe: only touches a dedicated namespace and a profile file on $W1.

# Recreate the working namespace.
kubectl delete namespace cks-apparmor --ignore-not-found --wait=false >/dev/null 2>&1
for i in $(seq 1 20); do kubectl get ns cks-apparmor >/dev/null 2>&1 || break; sleep 1; done
kubectl create namespace cks-apparmor >/dev/null 2>&1

# Remove any previously loaded profile / stale file so Step 1 starts fresh.
# (apparmor_parser -R is best-effort; the node may not have AppArmor here.)
docker exec "$W1" sh -c 'apparmor_parser -R /etc/apparmor.d/k8s-deny-write >/dev/null 2>&1; rm -f /etc/apparmor.d/k8s-deny-write' >/dev/null 2>&1

# Seed the target directory inside a future container is not needed; the path
# is referenced by the profile only. Nothing else to seed.
echo "cks-apparmor ready (namespace clean; stale profile removed on $W1)"
