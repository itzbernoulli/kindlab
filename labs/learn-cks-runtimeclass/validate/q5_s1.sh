#!/bin/bash
J=$(kubectl -n runtimeclass-learn get pod sandboxed -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ pod 'sandboxed' not found. Recreate it with gvisor + hardening."; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
sp=json.loads(os.environ['J'])["spec"]
def fail(m): print("❌ "+m); sys.exit(1)
if sp.get("runtimeClassName")!="gvisor": fail("must keep spec.runtimeClassName=gvisor (got %r)"%sp.get("runtimeClassName"))
psc=sp.get("securityContext") or {}
if psc.get("runAsNonRoot") is not True: fail("set pod spec.securityContext.runAsNonRoot: true (got %r)"%psc.get("runAsNonRoot"))
if psc.get("runAsUser")!=1000: fail("set pod spec.securityContext.runAsUser: 1000 (got %r)"%psc.get("runAsUser"))
cs=sp.get("containers",[])
if len(cs)!=1: fail("expected exactly one container (got %d)"%len(cs))
drop=(((cs[0].get("securityContext") or {}).get("capabilities") or {}).get("drop") or [])
if "ALL" not in drop: fail("container securityContext.capabilities.drop must contain ALL (got %r). capabilities is container-level."%drop)
print("✅ 'sandboxed' keeps gvisor, runs non-root (uid 1000), and drops ALL capabilities")
PY
