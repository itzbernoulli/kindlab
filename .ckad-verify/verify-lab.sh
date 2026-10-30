#!/bin/bash
# verify-lab.sh <lab-id> [settle-sec] — seed, apply solutions, check, report.
# SAFETY: pins the kind kubeconfig (worktree's .state); aborts if not on kind.
set -u
cd /Users/ayodeji/Workspace/kindlab/.claude/worktrees/ckad-slice
export KUBECONFIG=/Users/ayodeji/Workspace/kindlab/.claude/worktrees/ckad-slice/.state/kubeconfig
CTXNOW=$(kubectl config current-context 2>/dev/null)
case "$CTXNOW" in kind-*) ;; *) echo "ABORT: context '$CTXNOW' is not kind"; exit 1 ;; esac
NODES=$(kind get nodes --name kindlab 2>/dev/null)
export CP=$(echo "$NODES" | grep control-plane | head -1)
WK=$(echo "$NODES" | grep -v control-plane | tr '\n' ' ')
export WORKERS="$WK"
export W1=$(echo $WK | awk '{print $1}'); export W2=$(echo $WK | awk '{print $2}')
export CTX=kind-kindlab CTX2=kind-kindlab2 CLUSTER=kindlab
LAB="$1"
node bin/kindlab.js learn "$LAB" >/dev/null 2>&1
node -e "const d=require('./labs/$LAB/lab.json'); process.stdout.write(d.questions.map(q=>q.solution).join('\n'))" \
  | sed '/^kubectl get [a-z].* -w$/d; /^kubectl .* -w$/d' > /tmp/sol-$LAB.sh
bash /tmp/sol-$LAB.sh >/dev/null 2>&1
sleep "${2:-6}"
node bin/kindlab.js check "$LAB" 2>&1 | grep -iE "mastered|❌" | head -20
