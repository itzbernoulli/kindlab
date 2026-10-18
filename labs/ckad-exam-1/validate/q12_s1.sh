#!/bin/bash
NS=exam
J=pi-job
COMP=$(kubectl -n $NS get job $J -o jsonpath='{.spec.completions}' 2>/dev/null)
if [ -z "$COMP" ]; then echo "❌ Job '$J' not found in namespace $NS"; exit 1; fi
PAR=$(kubectl -n $NS get job $J -o jsonpath='{.spec.parallelism}' 2>/dev/null)
if [ "$COMP" != "4" ]; then echo "❌ completions must be 4 (got $COMP)"; exit 1; fi
if [ "$PAR" != "2" ]; then echo "❌ parallelism must be 2 (got '${PAR:-none}')"; exit 1; fi
SUCC=$(kubectl -n $NS get job $J -o jsonpath='{.status.succeeded}' 2>/dev/null)
if [ "${SUCC:-0}" != "4" ]; then echo "❌ Job must reach 4 successful completions (succeeded=${SUCC:-0})"; exit 1; fi
echo "✅ Job 'pi-job' has completions=4 parallelism=2 and succeeded 4 times"; exit 0
