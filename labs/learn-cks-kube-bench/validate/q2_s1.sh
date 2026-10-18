#!/bin/bash
# Strict: Job 'kube-bench-master' completed, ran on the control-plane node, and its
# logs contain CIS section 1.x (master/control-plane) findings.
NS=cks-bench
J=$(kubectl -n "$NS" get job kube-bench-master -o json 2>/dev/null)
[ -z "$J" ] && { echo "❌ Job 'kube-bench-master' not found in $NS. Create it (args run --targets master) pinned to the control plane."; exit 1; }
export J
python3 - <<'PY' || exit 1
import os,json,sys
j=json.loads(os.environ['J'])
def fail(m): print("❌ "+m); sys.exit(1)
if (j.get("status") or {}).get("succeeded",0) < 1: fail("Job 'kube-bench-master' has not completed yet (succeeded<1). Wait for it to finish.")
if j["spec"]["template"]["spec"].get("hostPID") is not True: fail("pod template must set hostPID: true")
print("ok")
PY
# The pod must have landed on the control-plane node.
NODE=$(kubectl -n "$NS" get pods -l job-name=kube-bench-master -o jsonpath='{.items[0].spec.nodeName}' 2>/dev/null)
if [ -z "$NODE" ]; then
  echo "❌ no pod found for Job kube-bench-master."; exit 1
fi
if [ "$NODE" != "$CP" ]; then
  echo "❌ kube-bench-master pod ran on '$NODE', not the control-plane node '$CP'. Pin it with a control-plane nodeSelector + toleration."; exit 1
fi
LOGS=$(kubectl -n "$NS" logs job/kube-bench-master 2>/dev/null)
if echo "$LOGS" | grep -Eq '\[(PASS|FAIL|WARN)\] 1\.'; then
  N=$(echo "$LOGS" | grep -Ec '\[(PASS|FAIL|WARN)\] 1\.')
  echo "✅ kube-bench-master ran on $CP with $N CIS section-1 (master) findings"; exit 0
fi
echo "❌ kube-bench-master completed on $CP but logs have no CIS section 1.x findings. Use args run --targets master so it audits the control plane."; exit 1
